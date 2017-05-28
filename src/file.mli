type t = {
  path : string;
  contents : string;
  lines : (string * Location.t) array;
}

val create : string -> t

(** 指定した行番号と列番号の位置のオフセットを返す *)
val offset : t -> int -> int -> int option

(** 指定したオフセットの行番号と列番号を返す *)
val index : t -> int -> (int * int) option

val shift_pos : t -> pos:Position.t -> len:int -> Position.t option
val shift_pos_exn : t -> pos:Position.t -> len:int -> Position.t
