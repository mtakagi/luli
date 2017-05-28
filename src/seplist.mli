type ('a, 'b) t
(** 'a と 'b が交互に現れる、要素が一つ以上のリスト。
  * コンマやセミコロンで区切られるノードのリストを表すのに使う。
  * 最後の要素は 'a と 'b のどちらでもよい。
  *)

(** リストを rev で逆転したデータ。
  * 最後尾の要素の型によって、逆転後の先頭の要素の型が異なる。
  *)
type ('a, 'b) rev =
  | RevA of ('a, 'b) t (** 先頭が 'a *)
  | RevB of ('b, 'a) t (** 先頭が 'b *)

(** 最後尾の要素 *)
type ('a, 'b) either =
  | A of 'a
  | B of 'b

val create : 'a -> ('a, 'b) t

val hd : ('a, 'b) t -> 'a
val tl : ('a, 'b) t -> ('b, 'a) t option
val last : ('a, 'b) t -> ('a, 'b) either

val rev_add : ('a, 'b) t -> 'b -> ('b, 'a) t
val rev_add_pair : ('a, 'b) t -> 'b -> 'a -> ('a, 'b) t
val rev : ('a, 'b) t -> ('a, 'b) rev

(* 逆転したリストの型を t に変換する。
 * ('a, 'b) rev の先頭が 'b であれば例外 Failure を発生させる。
 *)
val of_a_rev : ('a, 'b) rev -> ('a, 'b) t

(* 逆転したリストの型を t に変換する。
 * ('a, 'b) rev の先頭が 'a であれば例外 Failure を発生させる。
 *)
val of_b_rev : ('a, 'b) rev -> ('b, 'a) t

val fold : ('a, 'b) t -> init:'accu ->
  fa:('accu -> 'a -> 'accu) -> fb:('accu -> 'b -> 'accu) -> 'accu
val iter : ('a, 'b) t -> fa:('a -> unit) -> fb:('b -> unit) -> unit
val iteri : ('a, 'b) t -> fa:(int -> 'a -> unit) ->
  fb:(int -> 'b -> unit) -> unit

val length : ('a, 'b) t -> int
val length_a : ('a, 'b) t -> int
val length_b : ('a, 'b) t -> int
val is_singleton : ('a, 'b) t -> bool
(** 要素が一つであれば真 *)

val elements_a : ('a, 'b) t -> 'a list
val elements_b : ('a, 'b) t -> 'b list
val map_a : ('a, 'b) t -> f:('a -> 'c) -> 'c list
