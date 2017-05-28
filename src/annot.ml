open Core.Std

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

let annots_ref : t list ref =
  ref []

let annots () =
  List.rev !annots_ref

let add annot =
  annots_ref := annot :: !annots_ref

let at_line (loc : Location.t) =
  List.filter !annots_ref
    ~f:(fun ant -> loc.start.line = ant.loc.start.line)
