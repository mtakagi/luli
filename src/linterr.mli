include module type of Linterr_internal

type t = {
  path : string;
  loc : Location.t;
  code : Code.t;
}

val create : string -> Location.t -> Code.t -> t
val num : t -> int
val tag : t -> string
val loglv : t -> LogLv.t
val loglv_tag : t -> string
val is_warn : t -> bool
val message : t -> string

val contains_warn : t list -> bool
val contains_error : t list -> bool
val file_errors : t list -> string -> t list
val sort : t list -> t list
val filter_first : t list -> t list
