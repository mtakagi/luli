type t = {
  desc : desc;
  loc : Location.t;
}

and desc =
  | Directive of dir
  | Comment of comment

and dir =
  | Noqa

and comment = {
  range : [`Short | `Long];
  contents : string;
}

val annots : unit -> t list
val add : t -> unit
val at_line : Location.t -> t list
