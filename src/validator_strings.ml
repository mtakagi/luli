open Core.Std

let includes_single_quotes s =
  String.fold s ~init:`Char
    ~f:(fun accu c ->
        match accu with
        | `Found -> `Found
        | `Escape -> `Char
        | `Char ->
           match c with
           | '\\' -> `Escape
           | '\'' -> `Found
           | _ -> `Char) = `Found

let f = function
  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | String (quote, v) ->
      begin match quote with
      | Double_quoted ->
        if not @@ includes_single_quotes v.desc then
          Context.add_errcode ctx ast.loc Double_quoted_string
      | _ -> ()
      end
    | _ -> ()
    end
  | _ -> ()
