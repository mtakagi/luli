open Core.Std
open Ast_types

type indent = {
  indent_type : Indent_type.t;
  close_type : Close_type.t;
  size : int;
}

type t = {
  file : File.t;
  content : string;
  node : ast;
  mutable env : Env.t;
  mutable errs : Linterr.t list;
  mutable indent : indent list;
  mutable next_chunk_indent : int list;
  loading : Loading.t;
}

let create file content node env loading =
  { file = File.create file;
    content = content;
    node = node;
    env = env;
    errs = [];
    indent = [];
    next_chunk_indent = [];
    loading = loading;
  }

let file ctx =
  ctx.file

let scan ctx ~direction ~skip ~pos =
  Scanner.create ctx.file.contents ~direction ~skip ~pos

let forward_scan ?(skip=[]) ctx ~(loc : Location.t) =
  scan ctx ~direction:`Forward ~skip ~pos:loc.end_.offset

let backward_scan ?(skip=[]) ctx ~(loc : Location.t) =
  scan ctx ~direction:`Backward ~skip ~pos:(loc.start.offset - 1)

let global_env ctx =
  Env.root ctx.env

let is_top_env ctx =
  match Env.parent ctx.env with
  | None -> false
  | Some parent -> is_none @@ Env.parent parent

let create_env ctx =
  let env = Env.create (Some ctx.env) in
  ctx.env <- env;
  env

let destroy_env ctx =
  match Env.parent ctx.env with
  | Some e -> ctx.env <- e
  | None -> failwith "cannot destroy root erv"

let env ctx =
  ctx.env

let errors ctx =
  ctx.errs

let mem ctx k =
  Env.mem ctx.env k

let find ?(recur=true) ctx k =
  Env.find ~recur ctx.env k

let find_loc ctx k =
  match find ctx k with
  | Some var -> var.loc
  | None -> None

let suggest ctx k =
  Env.suggest ctx.env k

let set ctx v =
  Env.set ctx.env v

let set_global ctx (v : Env.Var.t) =
  v.global <- true;
  Env.set (global_env ctx) v

let set_vargs ctx loc =
  Env.set_vargs ctx.env loc

let add_err ctx err =
  ctx.errs <- err :: ctx.errs

let add_errcode ctx loc code =
  add_err ctx @@ Linterr.create ctx.file.path loc code

let current_indent ctx =
  match ctx.indent with
  | [] -> None
  | hd :: _ -> Some hd

let current_indent_type ctx =
  match current_indent ctx with
  | None -> Indent_type.No_indent
  | Some indent -> indent.indent_type

let current_indent_close_type ctx =
  match current_indent ctx with
  | None -> failwith "current_indent_close_type"
  | Some indent -> indent.close_type

let indent_depth indents =
  List.fold indents ~init:0 ~f:(fun accu indent -> accu + indent.size)

let current_indent_depth ctx =
  indent_depth ctx.indent

let prev_indent_depth ctx =
  match ctx.indent with
  | [] -> 0
  | _ :: tl -> indent_depth tl

let in_visual_indent ctx =
  List.exists ctx.indent ~f:(fun indent -> indent.indent_type = Visual_indent)

let new_indent_of_old old ~start ~end_ ~depth =
  let close =
    match old.close_type with
    | Trailing_close -> Indent.Trailing
    | Next_line_close -> New_line
  in
  let line_type =
    match old.indent_type with
    | No_indent -> Indent.Logical_line
    | Indent -> Logical_line
    | Visual_indent -> Cont_line (Visual, close)
    | Hanging_indent -> Cont_line (Hanging, close)
  in
  Indent.add ~line_type ~start ~end_ ~depth

let basic_indent ?(depth=(-1)) ?(close_type=Close_type.Next_line_close)
    ctx ~loc:(loc : Location.t) ~indent_type =
  let size =
    if depth >= 0 then
      depth - (current_indent_depth ctx)
    else
      !Conf.indent_size
  in
  let indent = { indent_type = indent_type;
                 close_type = close_type;
                 size = size }
  in
  ctx.indent <- indent :: ctx.indent;
  new_indent_of_old indent
                  ~start:loc.start.line
                  ~end_:loc.end_.line
                  ~depth:(current_indent_depth ctx)

let indent ?(depth=(-1)) ctx ~loc =
  basic_indent ctx ~indent_type:Indent_type.Indent ~depth ~loc

let indent_cont_line ?(depth=(-1)) ?(trail_close=false) ctx ~loc ~hanging =
  let open Indent_type in
  let open Close_type in
  let indent_type = if hanging then Hanging_indent else Visual_indent in
  let close_type = if trail_close then Trailing_close else Next_line_close in
  basic_indent ~loc ~indent_type ~close_type ~depth ctx

let dedent ctx =
  match ctx.indent with
  | [] -> failwith "dedent";
  | _ :: tl -> ctx.indent <- tl

let next_chunk_indent_depth ctx =
  match ctx.next_chunk_indent with
  | [] -> None
  | hd :: _ -> Some hd

let indent_next_chunk ctx =
  ctx.next_chunk_indent <- (current_indent_depth ctx + !Conf.indent_size)
                           :: ctx.next_chunk_indent

let dedent_next_chunk ctx =
  ctx.next_chunk_indent <- List.tl_exn ctx.next_chunk_indent

let parse_cont_lines ctx ~loc ~lb ~(rb : Location.t)
    ~last_elt_loc ~elements ~f ~rb_f =
  begin match Scanner.scan_newlines (forward_scan ctx ~loc:lb
                                       ~skip:[`Blank; `Comment]) with
  | Some _ ->
    (* 吊り下げインデント *)
    indent_cont_line ctx ~loc ~hanging:true
      ~trail_close:((match last_elt_loc with
                    | None -> lb
                    | Some loc -> loc).end_.line = rb.start.line);
    Option.iter elements ~f:(fun es -> List.iter es ~f);
    rb_f ();
    dedent ctx
  | None ->
    begin match elements with
    | None -> rb_f ()
    | Some elements' ->
      (* ビジュアルインデント *)
      let depth = lb.start.col + 1 in
      List.iter elements' ~f:(fun e ->
          indent_cont_line ctx ~loc ~hanging:false ~depth;
          f e;
          dedent ctx);

      (* 閉じ括弧 *)
      let scn = backward_scan ctx ~loc:rb in
      begin match Scanner.scan_indent scn with
      | None -> rb_f ()
      | Some _ ->
        indent_cont_line ctx ~loc ~hanging:false ~depth;
        rb_f ();
        dedent ctx
      end
    end
  end
