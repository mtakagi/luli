(** モジュールのロード状態を管理する *)

type module_ = {
  name : string;
  path : string;
  loc : Location.t;
  status : [ `Loaded | `Loading ];
}

type t

val create : unit -> t
val find : t -> name:string -> module_ option
val loading : t -> name:string -> path:string -> loc:Location.t -> unit
val finish_loading : t -> unit
val trace : t -> Location.t list
