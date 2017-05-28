open Core.Std

let f = function
  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | If (condbodylist, _else_opt, _end_) ->
      List.iter condbodylist
        ~f:(fun ({ desc = (_if_, exp, _, _chunk) } : Ast_types.condbody) -> 
            if Ast.is_true_cond exp then
              Context.add_errcode ctx exp.loc Meaningless_condition
            else if Ast.is_false_cond exp then
              Context.add_errcode ctx exp.loc Dead_block)
    | _ -> ()
    end

  | _ -> ()
