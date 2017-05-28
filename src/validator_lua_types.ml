open Core.Std

let f = function
  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
      | Bin_expr (left, op, right) ->
        (* 空文字列との結合 *)
        let concat (t : Ast_types.ast) =
          match t.desc with
          | Ast_types.String (_, v) ->
            if String.is_empty v.desc then begin
              Context.add_errcode ctx v.loc Concat_to_cast;
              true
            end else
              false
          | _ -> false
        in
        begin match op.desc with
          | Ast_types.Op_concat ->
            if not @@ concat left then
              let _ = concat right in
              ()
          | _ -> ()
        end

      | _ -> ()
    end

  | _ -> ()
