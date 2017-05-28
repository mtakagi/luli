open Core.Std

let f = function
  | Validator.Validate_file (_v, ctx, file) ->
    let lines = file.lines in
    let len = Array.length lines in
    if len > 1 then begin
      let (line1, loc1) = Array.get lines (len - 1) in
      let (line2, _loc2) = Array.get lines (len - 2) in
      let line1' = Xstring.drop_newlines line1 in
      let line2' = Xstring.drop_newlines line2 in
      if String.is_empty line1' && String.is_empty line2' then
        Context.add_errcode ctx loc1 Blank_line_at_end_of_file
    end
  | _ -> ()
