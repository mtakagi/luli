open Core.Std

val find_lib_path : string -> string option
val find_proj_conf : string -> string option

val is_noqa_error : Linterr.t -> bool
val filter_errors : Linterr.t list -> fname:string -> Linterr.t list
val contains_warns_to_error : Linterr.t list -> bool
val contains_error : Linterr.t list -> bool

val load : string -> (unit, string) Result.t
(** 設定ファイルをロードする *)

val init_proj_conf : unit -> string
