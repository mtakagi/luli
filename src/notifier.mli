(** イベントハンドラ *)

(** 'a に通知するイベントの型を指定する *)
type 'a t

(** 通知者を生成する *)
val create : ('a -> unit) list -> 'a t

(** イベントを通知する。イベントハンドラが評価される *)
val notify : 'a t -> 'a -> unit
