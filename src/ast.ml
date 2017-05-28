open Core.Std
open Ast_types

module AstUnaryOp = struct

  type t = unop

  let to_string { Location.desc = desc } =
    match desc with
    | Op_neg -> "-"
    | Op_not -> "not"
    | Op_len -> "#"

end

module AstBinOp = struct

  type t = binop

  let to_string { Location.desc = desc } =
    match desc with
    | Op_eq -> "=="
    | Op_ne -> "~="
    | Op_le -> "<="
    | Op_lt -> "<"
    | Op_ge -> ">="
    | Op_gt -> ">"
    | Op_add -> "+"
    | Op_sub -> "-"
    | Op_mul -> "*"
    | Op_div -> "/"
    | Op_rem -> "%"
    | Op_pow -> "^"
    | Op_and -> "and"
    | Op_or -> "or"
    | Op_concat -> ".."

end

module AstOp = struct

  type t = op

  let to_string = function
  | Unary_op op -> AstUnaryOp.to_string op
  | Bin_op op -> AstBinOp.to_string op

end

module AstDump = struct

  type t =
    | DNode of string * t list
    | DLeaf of string
    | DAtoms of string * string list
    | DStr of string * string

  let name = function
    | DNode (name, _) -> name
    | DLeaf name -> name
    | DAtoms (name, _) -> name
    | DStr (name, _) -> name

  let rec of_ast ast =
    let of_nodes name ts = DNode (name, List.map ts ~f:of_ast) in
    let of_word name (w : word) = DStr (name, w.desc) in
    let of_words name (words : wordlist) =
      DAtoms (name, Seplist.map_a words.desc ~f:(fun w -> w.desc))
    in
    let of_seplist name l f =
      DNode (name, Seplist.map_a l ~f)
    in
    let of_chunk name (chunk : chunk) =
      match chunk with
      | None -> DLeaf "emptystatlist"
      | Some v -> DNode (name, [of_nodes "statlist" v.desc])
    in
    let of_funcbody ({ desc = (_, parlist_opt, _, chunk, _) } : funcbody) =
      let par_of_ast = match parlist_opt with
      | Some parlist ->
        begin match parlist.desc with
        | Par_names (names, va_opt) ->
          let va_of_ast = match va_opt with
          | Some _ -> [DLeaf "vargs"]
          | None -> []
          in
          (of_words "parlist" names) :: va_of_ast
        | Par_vargs _ -> [DLeaf "vargs"]
        end
      | None -> []
      in
      DNode("funcbody", par_of_ast @ [of_chunk "block" chunk])
    in
    let of_explist (l : explist) =
      of_seplist "explist" l.desc of_ast
    in
    let of_args (args : args) =
      DNode ("args", match args.desc with
        | Args (_, Some explist, _) -> [of_explist explist]
        | Args (_, None, _) -> []
        | Lit_arg arg -> [of_ast arg])
    in
    let of_var (var : var) =
      match var.desc with
      | Atom name -> of_word "atom" name
      | Field_ref (prefix, _, name) ->
        DNode ("fieldref", [of_ast prefix; of_word "field" name])
      | Subscription (prefix, _, index, _) ->
        DNode ("subscription", [of_ast prefix; of_ast index])
    in
    let of_varlist (l : varlist) =
      of_seplist "varlist" l.desc of_var
    in
    match ast.desc with
    | Prog (chunk, _) -> of_chunk "prog" chunk
    | Nop _ -> DLeaf "nop"
    | Return (_, explist_opt) ->
      begin match explist_opt with
      | Some explist -> DNode ("return", [of_explist explist])
      | None -> DLeaf "return"
      end
    | Break _ -> DLeaf "break"
    | Label (_, name, _) -> of_word "label" name
    | Goto (_, name) -> of_word "goto" name
    | Nil _ -> DLeaf "nil"
    | Bool (_, false) -> DLeaf "false"
    | Bool (_, true) -> DLeaf "true"
    | Ellipsis _ -> DLeaf "ellipsis"
    | Assign (ls, _, rs) ->
      DNode ("assign", [of_varlist ls; of_explist rs])
    | Func_call (expr, args) ->
      DNode ("funccall", [of_ast expr; of_args args])
    | Method_call (expr, _, meth, args) ->
      DNode ("methodcall", [of_ast expr; of_word "name" meth; of_args args])
    | Do (_, block, _) -> DNode ("do", [of_chunk "block" block])
    | While (_, cond, _, block, _) ->
      DNode ("while", [of_ast cond; of_chunk "block" block])
    | Repeat (_, block, _, cond) ->
      DNode ("repeat", [of_chunk "block" block; of_ast cond])
    | If (condlist, else_opt, _) ->
      let cond_of_ast = List.concat (List.map condlist
        ~f:(fun { desc = (_, expr, _, block) } ->
          [of_ast expr; of_chunk "cond" block]))
      in
      let else_of_ast = match else_opt with
      | Some (_, block) -> [of_chunk "else" block]
      | None -> []
      in
      DNode ("if", cond_of_ast @ else_of_ast)
    (* TODO *)
    | Num_for (_,_,_,_,_,_,_,_,_,_) -> DNode ("numfor", [])
    | Gen_for (_,_,_,_,_,_,_) -> DNode ("genfor", [])
    | Func_def (_, names, body) ->
      DNode ("funcdef", [of_words "name" names; of_funcbody body])
    | Method_def (_, (prefix, _, name), body) ->
      DNode ("methoddef", [of_words "prefix" prefix;
        of_word "name" name; of_funcbody body])
    | Local_func_def (_, _, name, body) ->
      DNode ("localfuncdef", [of_word "name" name; of_funcbody body])
    | Local_var_def (_, names, explist_opt) ->
      let explist_of_ast = match explist_opt with
      | Some (_, explist) -> [of_explist explist]
      | None -> []
      in
      DNode ("localvardef", [of_words "namelist" names] @ explist_of_ast)
    | Var var -> of_var var
    | Number v -> of_word "number" v
    | String (_, v) -> of_word "string" v
    | Func (_, body) -> DNode ("func", [of_funcbody body])
    | Paren_expr (_, expr, _) -> DNode ("parenexpr", [of_ast expr])
    | Table (_, None, _) ->
      DNode ("tableconstructor", [])
    | Table (_, Some fs, _) ->
      DNode ("tableconstructor",
        [of_seplist "fieldlist" fs.desc of_ast])
    | Key_assoc _ -> DNode ("keyassoc", [])
    | Expr_assoc _ -> DNode ("exprassoc", [])
    | Bin_expr (left, op, right) ->
      DNode ("binexp", [of_ast left;
        DStr ("op", AstBinOp.to_string op); of_ast right])
    | Unary_expr (op, expr) ->
      DNode ("unexp", [DStr ("op", AstUnaryOp.to_string op); of_ast expr])

  let rec printi out i dump =
    let indent lv =
      for _j = 1 to lv do
        fprintf out "  "
      done
    in
    indent i;
    match dump with
    | DNode (name, subs) ->
      fprintf out "%s:\n" name;
      List.iter subs ~f:(fun sub -> printi out (i+1) sub)
    | DLeaf name -> fprintf out "%s\n" name
    | DAtoms (name, atoms) ->
      fprintf out "%s: " name;
      List.iter atoms ~f:(fun s -> fprintf out "\"%s\" " s);
      fprintf out "\n"
    | DStr (name, s) -> fprintf out "%s: \"%s\"\n" name s

  let print out (t : t) =
    printi out 0 t

end

module FuncBody = struct

  type t = funcbody

  let arity ({ desc = (_, ps_opt, _, _, _) } : t) =
    match ps_opt with
    | None -> 0
    | Some ps ->
      match ps.desc with
      | Par_names (ws, _) -> Seplist.length ws.desc
      | Par_vargs _ -> 0

  let parlist ({ desc = (_, parlist_opt, _, _, _) } : t) =
    parlist_opt

  let vargs ({ desc = (_, ps_opt, _, _, _) } : t) =
    match ps_opt with
    | None -> `Fixed_args
    | Some ps ->
      match ps.desc with
      | Par_vargs _ -> `Var_args
      | Par_names (_, vargs) ->
        match vargs with
        | Some _ -> `Var_args
        | None -> `Fixed_args

end

module Parlist = struct

  type t = parlist

  let params (t : t) =
    match t.desc with
    | Par_names (names, None) ->
      (Some (Seplist.elements_a names.desc), None)
    | Par_names (names, Some (_, vargs)) ->
      (Some (Seplist.elements_a names.desc), Some vargs)
    | Par_vargs vargs -> (None, Some vargs)

  let last_elt_loc (t : t) =
    match t.desc with
    | Par_names (names, None) -> (List.last_exn (Seplist.elements_a names.desc)).loc
    | Par_names (_, Some (_, vargs)) -> vargs
    | Par_vargs vargs -> vargs

end

type t = ast

let dump t =
  AstDump.print stdout (AstDump.of_ast t)

let rec unwrap (t : t) =
  match t.desc with
  | Paren_expr (_, exp, _) -> unwrap exp
  | _ -> t

let is_true_cond (t : t) =
  let t = unwrap t in
  match t.desc with
  | String _ -> true
  | Number _ -> true
  | Table _ -> true
  | Bool (_, true) -> true
  | _ -> false

let is_false_cond (t : t) =
  let t = unwrap t in
  match t.desc with
  | Bool (_, false) -> true
  | Nil _ -> true
  | _ -> false

let is_zero (t : t) =
  let t = unwrap t in
  match t.desc with
  | Number value -> value.desc = "0"
  | _ -> false
