(* 各行ごとの正しいインデントを保持するモジュール。
 * 現在はブロックコメントのインデント検査にのみ使っているが、
 * 将来的にはすべてのインデント検査にこのモジュールを使うべき。
 * TODO: その際、継続行インデントの情報をこのモジュールで登録する。
 *)

type t = {
  line_type : line_type;
  start : int;
  end_ : int;
  depth : int;
  mutable children : t list;
}

and line_type =
  | Logical_line
  | Cont_line of cont * close

and cont =
  | Visual
  | Hanging

and close =
  | Trailing
  | New_line

val is_logical_line : t -> bool
val is_cont_line : t -> bool

val find : f:(t -> bool) -> t option
val find_range : start:int -> end_:int -> t option
val find_lnum : lnum:int -> t option
val add : line_type:line_type -> start:int -> end_:int -> depth:int -> unit
