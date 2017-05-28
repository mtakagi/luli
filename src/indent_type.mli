type t =
  | No_indent
  | Indent
  | Visual_indent
  | Hanging_indent

val is_logical_line : t -> bool
val is_cont_line : t -> bool
