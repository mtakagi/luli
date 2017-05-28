open Core.Std

type 'a t

val create : unit -> 'a t
val distance : ?upper_bound: int -> string -> string -> int
val find : 'a t -> string -> 'a option
val find_or_add : 'a t -> string -> approx:(string -> 'a option) -> 'a option
val find_approx : ?range:int -> 'a String.Table.t -> string -> string option
val clear : 'a t -> unit
