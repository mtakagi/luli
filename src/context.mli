type t

val create : string -> string -> Ast_types.ast -> Env.t -> Loading.t -> t

val file : t -> File.t

val forward_scan : ?skip:Scanner.skip list -> t -> loc:Location.t -> Scanner.t
val backward_scan : ?skip:Scanner.skip list -> t -> loc:Location.t -> Scanner.t

val global_env : t -> Env.t
val is_top_env : t -> bool
val create_env : t -> Env.t
val destroy_env : t -> unit
val env : t -> Env.t
val errors : t -> Linterr.t list
val mem : t -> string -> bool
val find : ?recur:bool -> t -> string -> Env.Var.t option
val find_loc : t -> string -> Location.t option
val suggest : t -> string -> Env.Var.t option
(** 近い名前の変数を探す *)

val set : t -> Env.Var.t -> unit
(** ローカル変数を登録する *)

val set_global : t -> Env.Var.t -> unit
(** グローバル変数を登録する *)

val set_vargs : t -> Location.t -> unit
(** 可変長引数をローカル変数として登録する *)

val add_err : t -> Linterr.t -> unit
val add_errcode : t -> Location.t -> Linterr.Code.t -> unit

val current_indent_type : t -> Indent_type.t
val current_indent_close_type : t -> Close_type.t
val current_indent_depth : t -> int
val prev_indent_depth : t -> int
val in_visual_indent : t -> bool
val indent : ?depth:int -> t -> loc:Location.t -> unit
val indent_cont_line : ?depth:int -> ?trail_close:bool -> t -> loc:Location.t -> hanging:bool -> unit
val dedent : t -> unit
val next_chunk_indent_depth : t -> int option
val indent_next_chunk : t -> unit
val dedent_next_chunk : t -> unit
val parse_cont_lines : t -> loc:Location.t -> lb:Location.t -> rb:Location.t ->
  last_elt_loc:Location.t option -> elements:'a list option ->
  f:('a -> unit) -> rb_f:(unit -> unit) -> unit
