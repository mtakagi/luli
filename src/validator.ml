open Ast_types
open Core.Std

exception Load_error of string * Location.t list

type t = {
  genv : Env.t;
  notifier : event Notifier.t;
  mutable errs : Linterr.t list;
  loading : Loading.t;
}

and event =
  | Validate_file of (t * Context.t * File.t)
  | Validate_env_begin of (t * Context.t * Env.t)
  | Validate_env_end of (t * Context.t * Env.t)
  | Validate_ast_begin of (t * Context.t * Ast_types.ast)
  | Validate_ast_end of (t * Context.t * Ast_types.ast)
  | Validate_chunk_begin of (t * Context.t * Ast_types.chunk)
  | Validate_chunk_end of (t * Context.t * Ast_types.chunk)
  | Validate_funcbody_begin of (t * Context.t * Ast_types.funcbody)
  | Validate_funcbody_end of (t * Context.t * Ast_types.funcbody)
  | Validate_cont_line_end of (t * Context.t * Location.t * Location.t)

let create ~handlers =
  { genv = Env.global ();
    notifier = Notifier.create handlers;
    errs = [];
    loading = Loading.create (); 
  }

let loading v =
  v.loading

let do_block v ctx f =
  let env = Context.create_env ctx in
  Notifier.notify v.notifier (Validate_env_begin (v, ctx, env));
  f ();
  Notifier.notify v.notifier (Validate_env_end (v, ctx, env));
  Context.destroy_env ctx

let rec analyze_ast v ctx (ast : Ast_types.ast) =
  let do_pre_chunk f =
    Context.indent_next_chunk ctx;
    f ();
    Context.dedent_next_chunk ctx
  in
  Notifier.notify v.notifier (Validate_ast_begin (v, ctx, ast));
  begin match ast.desc with
  | Prog (chunk, end_) ->
    do_block v ctx (fun () ->
      analyze_chunk ~indent:false v ctx chunk ~open_loc:ast.loc ~close_loc:end_)

  | Return (_ret, explist_opt) ->
    analyze_explist_opt v ctx explist_opt

  | Assign (varlist, _eq, explist) ->
    analyze_explist v ctx explist;
    analyze_varlist v ctx varlist

  | Func_call (exp, args) ->
    (* TODO: visitor で処理したいが、 visitor に validator を
     * 渡せる構造になっていない (モジュールの依存関係が複雑)
     *)
    let find_require (ast : Ast_types.ast) (args : Ast_types.args) =
      let rec find_arg (arg : Ast_types.ast) =
        match arg.desc with
          | String (_, path) ->
            Conf.verbose "require `%s' at \"%s\""
              path.desc (Context.file ctx).path;
            Some path.desc
          | Paren_expr (_, exp, _) -> find_arg exp
          | _ -> None
      in
      let find_args = function
        | Args (_, None, _) -> None
        | Args (_, Some explist, _) ->
            if Seplist.length explist.desc <> 1 then
              None
            else
              find_arg @@ Seplist.hd explist.desc
        | Lit_arg arg -> find_arg arg
      in
      match ast.desc with
      | Var var ->
        begin match var.desc with
        | Atom name ->
          if name.desc = "require" then
            find_args args.desc
          else
            None
        | _ -> None
        end
     | _ -> None
    in

    (* require によるモジュールのロード *)
    if !Conf.autoload && Context.is_top_env ctx then begin
      match find_require exp args with
      | None -> ()
      | Some name ->
        let loc = args.loc in
        match load_module v ctx loc name with
        | `Success -> ()
        | `Not_found _ -> Context.add_errcode ctx loc (Module_not_found name)
        | `Cyclic_load _ ->
          Context.add_errcode ctx loc (Cyclic_load name)
    end;

    analyze_ast v ctx exp;
    analyze_args v ctx args

  | Method_call (exp, _colon, _name, args) ->
    analyze_ast v ctx exp;
    analyze_args v ctx args

  | Do (do_, chunk, end_) ->
    analyze_chunk v ctx chunk ~open_loc:do_ ~close_loc:end_

  | Repeat (repeat, chunk, until, exp) ->
    analyze_chunk v ctx chunk ~open_loc:repeat ~close_loc:until;
    analyze_ast v ctx exp

  | While (_while_, exp, do_, chunk, end_) ->
    do_pre_chunk (fun () -> analyze_ast v ctx exp);
    analyze_chunk v ctx chunk ~open_loc:do_ ~close_loc:end_

  | If (condbodylist, else_opt, end_) ->
    let last_close_loc =
      match else_opt with
      | None -> end_
      | Some (else_, _) -> else_
    in
    let rec analyze_condbodylist : condbody list -> unit = function
      | [] -> ()
      | { desc = (_if_, exp, then_, chunk) } :: [] ->
        do_pre_chunk (fun () -> analyze_ast v ctx exp);
        analyze_chunk v ctx chunk ~open_loc:then_ ~close_loc:last_close_loc
      | { desc = (_if_, exp, then_, chunk) } :: next :: tl ->
        do_pre_chunk (fun () -> analyze_ast v ctx exp);
        let (close_loc, _, _, _) = next.desc in
        analyze_chunk v ctx chunk ~open_loc:then_ ~close_loc;
        analyze_condbodylist (next :: tl)
    in
    do_block v ctx (fun () ->
      analyze_condbodylist condbodylist;
      begin match else_opt with
      | None -> ()
      | Some (else_, chunk) ->
        analyze_chunk v ctx chunk ~open_loc:else_ ~close_loc:end_
      end)

  | Num_for (_for_, _name, _eq, init_exp, _comma1, max_exp,
            step_opt, do_, chunk, end_) ->
    do_block v ctx (fun () ->
      do_pre_chunk (fun () -> analyze_ast v ctx init_exp);
      do_pre_chunk (fun () -> analyze_ast v ctx max_exp);
      begin match step_opt with
      | Some (_, exp) ->
        do_pre_chunk (fun () -> analyze_ast v ctx exp)
      | None -> ()
      end;
      analyze_chunk v ctx chunk ~open_loc:do_ ~close_loc:end_)

  | Gen_for (_for_, _namelist, _in_, explist, do_, chunk, end_) -> 
    do_block v ctx (fun () ->
      do_pre_chunk (fun () -> analyze_explist v ctx explist);
      analyze_chunk v ctx chunk ~open_loc:do_ ~close_loc:end_)

  | Func_def (_fun_, _names, body) ->
    analyze_funcbody v ctx body

  | Method_def (_fun_, _meth, body) ->
    analyze_funcbody v ctx body

  | Local_func_def (_local, _fun_, _name, body) ->
    analyze_funcbody v ctx body

  | Local_var_def (_local, _namelist, right_opt) ->
    begin match right_opt with
    | Some (_, explist) -> analyze_explist v ctx explist
    | None -> ()
    end

  | Var var ->
    analyze_var v ctx var

  | Nil _t -> ()
  | Number _t -> ()
  | Bool (_t, _v) -> ()
  | String (_quote, _v) -> ()

  | Func (fun_, body) ->
    Context.indent_cont_line ctx ~loc:ast.loc ~hanging:false
      ~depth:fun_.start.col;
    analyze_funcbody v ctx body;
    Context.dedent ctx

  | Paren_expr (_lp, exp, _rp) ->
    analyze_ast v ctx exp

  | Table (lb, fieldlist_opt, rb) ->
    analyze_cont_lines v ctx ~loc:ast.loc ~lb ~rb
      ~elements:Option.(fieldlist_opt >>| (fun l -> Seplist.elements_a l.desc))
      ~last_elt_loc:Option.(fieldlist_opt >>| fun l -> l.loc)

  | Key_assoc (_key, _eq, exp) ->
    analyze_ast v ctx exp

  | Expr_assoc (_lb, keyexp, _rb, _eq, valexp) ->
    analyze_ast v ctx keyexp;
    analyze_ast v ctx valexp

  | Bin_expr (left, _op, right) ->
    analyze_ast v ctx left;
    analyze_ast v ctx right

  | Unary_expr (_op, exp) ->
    analyze_ast v ctx exp

  | _ -> ()
  end;
  Notifier.notify v.notifier (Validate_ast_end (v, ctx, ast))

and analyze_chunk ?(indent=true) v ctx chunk_opt ~open_loc ~close_loc =
  if indent then begin
    Context.indent ctx ~loc:open_loc;
    let start = open_loc.end_.line in
    let end_ = close_loc.start.line in
    if end_ - start > 1 then
      Indent.add ~line_type:Logical_line
        ~start:(start + 1)
        ~end_:(end_ - 1)
        ~depth:(Context.current_indent_depth ctx)
  end;
  Notifier.notify v.notifier (Validate_chunk_begin (v, ctx, chunk_opt));
  begin match chunk_opt with
  | None -> ()
  | Some chunk ->
    List.iter chunk.desc ~f:(fun stat -> analyze_ast v ctx stat);
  end;
  Notifier.notify v.notifier (Validate_chunk_end (v, ctx, chunk_opt));
  if indent then
    Context.dedent ctx

and analyze_funcbody v ctx
  ({ desc = (_lp, _parlist_opt, rp, chunk, end_) } as body) =
  do_block v ctx
    (fun () ->
       Notifier.notify v.notifier (Validate_funcbody_begin (v, ctx, body));
       analyze_chunk v ctx chunk ~open_loc:rp ~close_loc:end_;
       Notifier.notify v.notifier (Validate_funcbody_end (v, ctx, body)))

and analyze_explist_opt v ctx = function
  | Some explist -> analyze_explist v ctx explist
  | None -> ()

and analyze_explist v ctx explist =
  List.iter (Seplist.elements_a explist.desc) ~f:(analyze_ast v ctx)

and analyze_varlist v ctx varlist =
  List.iter (Seplist.elements_a varlist.desc) ~f:(analyze_var v ctx)

and analyze_var v ctx var =
  match var.desc with
  | Ast_types.Atom _name -> ()
  | Field_ref (target, _dot, _name) ->
    analyze_ast v ctx target
  | Subscription (target, _lb, key, _rb) ->
    analyze_ast v ctx target;
    analyze_ast v ctx key

and analyze_args v ctx args =
  match args.desc with
  | Args (lb, explist_opt, rb) ->
    analyze_cont_lines v ctx ~loc:args.loc ~lb ~rb
      ~elements:Option.(explist_opt >>| (fun l -> Seplist.elements_a l.desc))
      ~last_elt_loc:Option.(explist_opt >>| fun l -> l.loc)
  | Lit_arg t ->
    analyze_ast v ctx t

and analyze_cont_lines v ctx ~loc ~lb ~rb ~elements ~last_elt_loc =
  let f = analyze_ast v ctx in
  Context.parse_cont_lines ctx ~loc ~lb ~rb ~last_elt_loc ~elements ~f
    ~rb_f:(fun () ->
        Notifier.notify v.notifier (Validate_cont_line_end (v, ctx, lb, rb)))

and analyze' v file =
  let inx = In_channel.create file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.Lexing.lex_curr_p <-
   { lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = file };
  Lexer.skip_sharp lexbuf;

  try begin
    let ast = Parser.prog Lexer.read lexbuf in
    if !Conf.debug_mode then Ast.dump ast;
    let inx = In_channel.create file in
    let ctx = Context.create file (In_channel.input_all inx)
        ast v.genv v.loading in
    In_channel.close inx;
    analyze_ast v ctx ast;

    (* analyze_ast で解析されるインデント情報を利用するため、最後に呼ぶ *)
    Notifier.notify v.notifier (Validate_file (v, ctx, (Context.file ctx)));

    List.rev @@ Context.errors ctx
  end with
  | Lexer.Syntax_error msg -> [Lexer.syntax_error lexbuf msg]
  | Lexer.Directive_error msg -> [Lexer.directive_error lexbuf msg]
  | Parser.Error -> [Lexer.syntax_error lexbuf "invalid syntax"]

and analyze v file =
  let errs = analyze' v file in
  v.errs <- List.concat [v.errs; errs];
  errs

(* ソースファイルをロードする *)
and load v path =
  match Sys.file_exists path with
  | `Yes ->
    Conf.verbose "load \"%s\"" path;
    `Success (analyze v path)
  | _ ->
    `Failure

(* モジュールをロードする。ロードパスからモジュールを探す *)
and load_module v ctx loc name =
  let open Loading in
  Conf.verbose "try loading module `%s'" name;

  (* すでに同名のモジュールがロードされているか *)
  match Loading.find v.loading ~name with
  | Some m ->
    begin match m.status with
    | `Loaded ->
      Conf.verbose "module already loaded `%s'" name;
      `Success
    | `Loading ->
      Conf.verbose "cyclic loading module `%s'" name;
      `Cyclic_load (Loading.trace v.loading)
    end
  | None ->
    begin match Project.find_lib_path name with
    | None ->
      `Not_found (Loading.trace v.loading)
    | Some path ->
      (* モジュールの発見成功、ロードする *)
      Loading.loading v.loading ~name ~path ~loc;
      let res =
        match load v path with
        | `Success errs ->
          begin match List.find_map errs ~f:(fun e ->
              match e.code with
              | Syntax_error _ -> Some (Linterr.Code.Syntax_error_in_module name)
              | Syntax_error_in_module name' -> Some (Syntax_error_in_module name')
              | Module_not_found name' -> Some (Module_not_found name')
              | Cyclic_load name' -> Some (Cyclic_load name')
              | _ -> None)
          with
          | None -> ()
          | Some code -> Context.add_errcode ctx loc code
          end;
          Loading.finish_loading v.loading;
          `Success
        | `Failure -> `Not_found (Loading.trace v.loading)
      in
      Conf.verbose "module loaded `%s'" name;
      res
    end

let validate v file =
  let _ = analyze v file in
  ()

let errors v =
  v.errs
