open Core.Std
open UCoreLib

let f = function
  | Validator.Validate_file (_v, ctx, file) ->
    Array.iter file.lines ~f:(fun (line, (loc : Location.t)) ->
        let line' = Xstring.drop_newlines line in
        let len =
          try Text.length @@ Text.of_string line' with
          | Malformed_code -> String.length line'
        in
        if len > !Conf.max_line_length then begin
          let start = { loc.start with col = !Conf.max_line_length } in
          let over_loc = Location.create start loc.end_ in
          Context.add_errcode ctx over_loc @@
            Line_too_long (len, !Conf.max_line_length)
        end)
  | _ -> ()
