open Ast_types
open Core.Std

let nspaces (scan : ?skip:Scanner.skip list -> Context.t ->
             loc:Location.t -> Scanner.t) ctx (loc : Location.t)
  : (int * [`Char | `Newline | `EOF]) =
  let scn = scan ctx ~loc in
  match Scanner.scan_spaces scn with
  | None ->
    if Scanner.end_of_line scn then
      (0, `Newline)
    else
      (0, `Char)
  | Some s ->
    let len = String.length s in
    if Scanner.end_of_string scn then
      (len, `EOF)
    else if Scanner.end_of_line scn then
      (len, `Newline)
    else
      (len, `Char)

let nspaces_before =
  nspaces Context.backward_scan

let nspaces_after =
  nspaces Context.forward_scan

let exists_single_space = function
  | (_, `Newline) -> `Valid
  | (_, `EOF) -> `Valid
  | (1, `Char) -> `Valid
  | (0, `Char) -> `Missing
  | (len, `Char) -> `Multiple len

let validate_single_space_around_op ctx loc s =
  let open Linterr.Code in
  let before =
    match exists_single_space @@ nspaces_before ctx loc with
    | `Valid -> None
    | `Missing ->
      let start = File.shift_pos_exn (Context.file ctx) ~pos:loc.start ~len:(-1) in
      Some (Location.create start loc.start, Missing_whitespace_around_op s)
    | `Multiple _ ->
      let start = File.shift_pos_exn (Context.file ctx) ~pos:loc.start ~len:(-1) in
      Some (Location.create start loc.start, Multiple_whitespaces_before_op s)
  in
  let after =
    match exists_single_space @@ nspaces_after ctx loc with
    | `Valid -> None
    | `Missing -> Some (loc, Missing_whitespace_around_op s)
    | `Multiple len ->
      let end_ = File.shift_pos_exn (Context.file ctx) ~pos:loc.end_ ~len in
      Some (Location.create loc.end_ end_, Multiple_whitespaces_after_op s)
  in
  List.iter [before; after]
    ~f:(function
        | None -> ()
        | Some (loc, code) -> Context.add_errcode ctx loc code)

let validate_single_space_around_binop ctx (op : Ast_types.binop) =
  validate_single_space_around_op ctx op.loc (Ast.AstBinOp.to_string op)

let validate_single_space_around_eq ctx loc =
  validate_single_space_around_op ctx loc "="

let validate_no_spaces_after ctx loc code =
  match nspaces_after ctx loc with
  | (0, _) -> ()
  | (_, `Newline) -> ()
  | (len, _) ->
    let start = loc.end_ in
    let end_ = File.shift_pos_exn (Context.file ctx) ~pos:loc.end_ ~len in
    Context.add_errcode ctx (Location.create start end_) code

let validate_no_spaces_before ctx loc code =
  let scn = Context.backward_scan ctx ~loc in
  match Scanner.scan_spaces scn with
  | None -> ()
  | Some _ ->
    if not @@ Scanner.end_of_line scn then
      let start = File.shift_pos_exn (Context.file ctx)
          ~pos:loc.start ~len:(-1) in
      Context.add_errcode ctx (Location.create start loc.start) code

let validate_no_spaces_after_lbrack ctx loc s =
  validate_no_spaces_after ctx loc (Whitespace_afterLBrack s)

let validate_no_spaces_before_rbrack ctx loc s =
  validate_no_spaces_before ctx loc (Whitespace_beforeRBrack s)

let validate_no_spaces_around_bracks ctx lloc rloc ls rs =
  let open Location in
  validate_no_spaces_after_lbrack ctx lloc ls;
  if rloc.start.offset - lloc.start.offset > 2 then
    validate_no_spaces_before_rbrack ctx rloc rs

let lparen = "("
let rparen = ")"
let lbrace = "{"
let rbrace = "}"
let lbrack = "["
let rbrack = "]"

let validate_no_spaces_before_lparen ctx loc =
  validate_no_spaces_before ctx loc Whitespace_beforeLParen

let validate_single_space_after ctx loc miss much =
  match nspaces_after ctx loc with
  | (1, `Char) -> ()
  | (0, `Char) -> Context.add_errcode ctx loc miss 
  | (len, `Char) ->
    let start = loc.end_ in
    let end_ = File.shift_pos_exn (Context.file ctx) ~pos:start ~len in
    Context.add_errcode ctx (Location.create start end_) much
  | _ -> ()

let validate_no_spaces_before_comma ctx loc =
  validate_no_spaces_before ctx loc (Whitespace_before_sign ",")

let validate_single_space_after_comma ctx loc =
  validate_single_space_after ctx loc
    Missing_whitespace_after_comma Multiple_whitespaces_after_comma

let validate_single_space_before ctx loc ~missing ~multiple =
  let scn = Context.backward_scan ctx ~loc in
  match Scanner.scan_spaces scn with
  | None -> Context.add_errcode ctx loc missing
  | Some s ->
    match String.length s with
    | 1 -> ()
    | len ->
      if not @@ Scanner.end_of_line scn then
        let start = File.shift_pos_exn (Context.file ctx)
            ~pos:loc.start ~len:(-len) in
        let end_ = File.shift_pos_exn (Context.file ctx) ~pos:start ~len in
        Context.add_errcode ctx (Location.create start end_) multiple

let validate_sepl ctx l exists miss much =
  let last = (Seplist.length l) - 1 in
  Seplist.iteri l
    ~fa:(fun i e ->
           if i < last then
             validate_no_spaces_after ctx e.Location.loc exists)
    ~fb:(fun i sep ->
           if i < last then
             validate_single_space_after ctx sep miss much)

let validate_comma_sepl ctx l =
  validate_sepl ctx l (Whitespace_before_sign ",")
    Missing_whitespace_after_comma Multiple_whitespaces_after_comma

let validate_args ctx (args : args) =
  match args.desc with
  | Args (lp, explist, rp) ->
    validate_no_spaces_before_lparen ctx lp;
    validate_no_spaces_after_lbrack ctx lp lparen;
    validate_no_spaces_before_rbrack ctx rp rparen;
    begin match explist with
    | None -> ()
    | Some explist' ->
      validate_comma_sepl ctx explist'.desc
    end
  | Lit_arg t ->
    (* TODO: 複数スペースの検査 *)
    match nspaces_before ctx t.loc with
    | (1, _) -> ()
    | (0, _) ->
      Context.add_errcode ctx t.loc Missing_whitespace_before_literal_arg
    | _ -> ()

let validate_func_arg_parens ctx { Location.desc = (lp, _, rp, _, _) } =
  validate_no_spaces_before_lparen ctx lp;
  validate_no_spaces_after_lbrack ctx lp lparen;
  validate_no_spaces_before_rbrack ctx rp rparen

let validate_fieldlist ctx (l : Ast_types.fieldlist) =
  let last = (Seplist.length l.desc) - 1 in
  let pre = ref None in
  Seplist.iteri l.desc
    ~fa:(fun _i e -> pre := Some e)
    ~fb:(fun i sep ->
           (* TODO: セミコロン前後のエラーコードを定義する *)
           if i < last then begin
             begin match !pre with
             | None -> ()
             | Some e ->
               validate_no_spaces_after ctx e.loc
                 begin match sep.desc with
                 | `Comma -> (Whitespace_before_sign ",")
                 | `Semi -> (Whitespace_before_sign ";")
                 end
             end;
           end;
           validate_single_space_after ctx sep.loc
             begin match sep.desc with
             | `Comma -> Missing_whitespace_after_comma
             | `Semi -> Missing_whitespace_after_comma
             end
             begin match sep.desc with
             | `Comma -> Multiple_whitespaces_after_comma
             | `Semi -> Multiple_whitespaces_after_comma
             end)

let f = function
  | Validator.Validate_file (_v, ctx, file) ->
    Array.iter file.lines ~f:(fun (line, (loc : Location.t)) ->
        let rec scan i accu =
          match Xstring.get_opt line i with
          | None -> accu
          | Some ' ' -> scan (i-1) (accu+1)
          | Some '\t' -> scan (i-1) (accu+1)
          | Some '\r' -> scan (i-1) accu
          | Some '\n' -> scan (i-1) accu
          | Some _ -> accu
        in
        match scan (String.length line - 1) 0 with
        | 0 -> ()
        | n ->
          let start = File.shift_pos_exn (Context.file ctx)
              ~pos:Location.(loc.end_) ~len:(-n-1) in
          Context.add_errcode ctx (Location.create start loc.end_)
            Trailing_whitespace)

  | Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | Assign (varlist, eq, explist) ->
      validate_single_space_around_eq ctx eq;
      validate_comma_sepl ctx varlist.desc;
      validate_comma_sepl ctx explist.desc

    | Func_call (_exp, args) ->
      validate_args ctx args

    | Method_call (_exp, colon, _name, args) ->
      validate_no_spaces_before ctx colon (Whitespace_before_sign ":");
      validate_no_spaces_after ctx colon (Whitespace_after_sign ":");
      validate_args ctx args

    | Num_for (_for_, _name, eq, _init_exp, comma1, _max_exp,
               step_opt, _do_, _chunk, _end_) ->
      validate_single_space_around_eq ctx eq;
      validate_no_spaces_before_comma ctx comma1;
      validate_single_space_after_comma ctx comma1;
      begin match step_opt with
        | Some (comma2, _exp) ->
          validate_no_spaces_before_comma ctx comma2;
          validate_single_space_after_comma ctx comma2
        | None -> ()
      end

    | Gen_for (_for_, namelist, _in_, explist, _do_, _chunk, _end_) ->
      validate_comma_sepl ctx namelist.desc;
      validate_comma_sepl ctx explist.desc

    | Func_def (_fun_, _names, body) ->
      validate_func_arg_parens ctx body

    | Method_def (_fun_, (_names, _colon, _meth), body) ->
      validate_func_arg_parens ctx body

    | Local_func_def (_local_, _fun_, _name, body) ->
      validate_func_arg_parens ctx body

    | Local_var_def (_local, names, explist_opt) ->
      validate_comma_sepl ctx names.desc;
      begin match explist_opt with
      | Some (eq, explist) ->
        validate_single_space_around_eq ctx eq;
        validate_comma_sepl ctx explist.Location.desc
      | None -> ()
      end

    | Paren_expr (lp, _exp, rp) ->
      validate_no_spaces_around_bracks ctx lp rp lparen rparen

    | Table (lb, fieldlist_opt, rb) ->
      validate_no_spaces_around_bracks ctx lb rb lbrace rbrace;
      begin match fieldlist_opt with
      | None -> ()
      | Some fieldlist -> validate_fieldlist ctx fieldlist
      end

    | Key_assoc (_key, eq, _exp) ->
      validate_single_space_around_eq ctx eq

    | Expr_assoc (lb, _keyexp, rb, eq, _valexp) ->
      validate_no_spaces_around_bracks ctx lb rb lbrack rbrack;
      validate_single_space_around_eq ctx eq

    | Bin_expr (_left, op, _right) ->
      validate_single_space_around_binop ctx op

    | Unary_expr (op, _exp) ->
      if op.desc = Op_len || op.desc = Op_neg then
        let sign = Ast.AstUnaryOp.to_string op in
        validate_no_spaces_after ctx op.loc (Whitespace_after_sign sign)

    | Func (_function_, { desc = (lp, _, _, _, _)}) ->
      validate_single_space_before ctx lp
        ~missing:Missing_whitespace_before_lparen
        ~multiple:Multiple_whitespaces_before_lparen

    | Var var ->
      begin match var.desc with
      | Ast_types.Atom _name -> ()
      | Field_ref (_table, dot, _field) ->
        validate_no_spaces_before ctx dot (Whitespace_before_sign ".");
        validate_no_spaces_after ctx dot (Whitespace_after_sign ".")
      | Subscription (_target, lb, _key, rb) ->
        validate_no_spaces_after_lbrack ctx lb lbrack;
        validate_no_spaces_before_rbrack ctx rb rbrack
      end

    | _ -> ()
    end

  | Validate_funcbody_begin (_v, ctx, ast) ->
    let (_lp, parlist_opt, _rp, _chunk, _end_) = ast.desc in
    begin match parlist_opt with
    | None -> ()
    | Some parlist ->
      begin match parlist.desc with
      | Par_names (names, _vargs) ->
        validate_comma_sepl ctx names.desc
      | Par_vargs _loc -> ()
      end
    end

  | _ -> ()
