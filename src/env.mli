open Core.Std

module Var : sig

  type t = {
    name : string;
    loc : Location.t option;
    mutable used : bool;
    mutable global : bool;
  }

  val create : ?loc:Location.t -> string -> t
  val with_locd : string Location.loc -> t

end

type t = {
  parent : t option;
  tbl : Var.t String.Table.t;
  spell : Var.t Spell_check.t;
}

val create : t option -> t
val global : unit -> t
val parent : t -> t option
val root : t -> t
val find_env : ?recur:bool -> t -> string -> t option
val table : t -> Var.t String.Table.t
val mem : t -> string -> bool
val find : ?recur:bool -> t -> string -> Var.t option
val set : t -> Var.t -> unit
val set_vargs : t -> Location.t -> unit
val replace : t -> Var.t -> unit
val iter : t -> (Var.t -> unit) -> unit
val suggest : t -> string -> Var.t option
