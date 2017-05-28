open Core.Std
open Ast_types

let is_compound_exp (exp : ast) =
  match exp.desc with
  | Paren_expr (_, exp', _) ->
    begin match exp'.desc with
    | Bin_expr _ -> true
    | Unary_expr _ -> true
    | _ -> false
    end
  | _ -> false

let validate_exp ctx exp =
  if is_compound_exp exp then
    Context.add_errcode ctx exp.loc Redundant_paren

let validate_explist ctx (explist : explist) =
  Seplist.elements_a explist.desc |> List.iter ~f:(validate_exp ctx)

let validate_var ctx = function
  | Atom _ -> ()
  | Field_ref (exp, _, _) -> validate_exp ctx exp
  | Subscription (exp, _, index, _) ->
    validate_exp ctx exp;
    validate_exp ctx index

let f = function
  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | Paren_expr (_lp, exp, _rp) ->
      if (match exp.desc with
          | Nil _ -> true
          | Bool _ -> true
          | Number _ -> true
          | String _ -> true
          | Ellipsis _ -> true
          | Func _ -> true
          | Paren_expr _ -> true
          | Table _ -> true
          | Var _ -> true
          | _ -> false) then
        Context.add_errcode ctx ast.loc Redundant_paren

    | Var var ->
      validate_var ctx var.desc

    | Assign (varlist, _eq, explist) ->
      validate_explist ctx explist;
      Seplist.elements_a varlist.desc
      |> List.iter ~f:(fun (var : var) -> validate_var ctx var.desc)

    | Local_var_def (_local, _names, explist) ->
      begin match explist with
      | None -> ()
      | Some (_eq, explist') -> validate_explist ctx explist'
      end

    | If (condbodylist, _else_, _end_) ->
      List.iter condbodylist ~f:(fun { desc = (_, exp, _, _) } ->
          validate_exp ctx exp)

    | While (_while_, cond, _do_, _chunk, _end_) ->
      validate_exp ctx cond

    | Repeat (_repeat_, _chunk, _until_, cond) ->
      validate_exp ctx cond

    | Func_call (_exp, args) ->
      begin match args.desc with
      | Lit_arg _ -> ()
      | Args (_, None, _) -> ()
      | Args (_, Some explist, _) -> validate_explist ctx explist
      end

    | Key_assoc (_key, _eq, exp) ->
      validate_exp ctx exp

    | Expr_assoc (_lb, keyexp, _rb, _eq, valexp) ->
      validate_exp ctx keyexp;
      validate_exp ctx valexp

    | Unary_expr (_op, exp) ->
      validate_exp ctx exp

    | _ -> ()
    end

  | _ -> ()
