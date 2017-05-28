(** 文字列スキャナ *)

module Indent : sig

  type t

  val depth : t -> int
  val contains_tabs : t -> bool

end

type t
type direction = [`Forward | `Backward]
type skip = [`Blank | `Newline | `Comment]

val create : ?direction:direction ->
  ?skip:skip list ->
  ?pos:int -> string -> t

val end_of_line : t -> bool
val end_of_string : t -> bool

val scan : t -> f:(char -> bool) -> string option
val scan_spaces : t -> string option
val scan_newlines : t -> string option
val scan_indent : t -> Indent.t option
