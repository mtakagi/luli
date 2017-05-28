open Core.Std

val is_newline : char -> bool
val join : ?sep:string -> string list -> string
val normpath : string -> string

(** 複合名 (ドットを含むモジュール名) のドットをディレクトリ区切り文字に変換する *)
val modname_to_path : string -> string

val exec_cmd : string -> string list * Unix.Exit_or_signal.t

(** seplist の両端の要素を境界とする範囲付き seplist を返す *)
val seplist_to_loc : ('a, 'b) Seplist.t ->
  fa:('a -> Location.t) -> fb:('b -> Location.t) ->
  ('a, 'b) Seplist.t Location.loc

(** seplist の両端の要素を境界とする範囲付き seplist を返す。
 * ただし、 seplist の両端の要素は 'a loc でなければならない。
 * "exp1, exp2, ..." のように構文木を区切る seplist に対して使う。
 *)
val delim_seplist_to_loc : ('a Location.loc, Location.t) Seplist.t ->
  ('a Location.loc, Location.t) Seplist.t Location.loc
