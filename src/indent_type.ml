type t =
  | No_indent
  | Indent
  | Visual_indent
  | Hanging_indent

let is_logical_line = function
  | No_indent -> true
  | Indent -> true
  | _ -> false

let is_cont_line = function
  | Visual_indent -> true
  | Hanging_indent -> true
  | _ -> false
