open Core.Std

module Indent = struct

  type t = string

  let zero = ""

  let create s =
    s

  let depth t =
    String.length t

  let contains_tabs t =
    String.contains t '\t'

end

type direction = [`Forward | `Backward]
type skip = [`Blank | `Newline | `Comment]

type t = {
  contents : string;
  mutable pos : int;
  direction : direction;
  skip_blank : bool;
  skip_nl : bool;
  skip_comment : bool;
}

let create ?(direction=`Forward) ?(skip=[]) ?(pos=0) contents =
  { contents = contents;
    pos = pos;
    direction = direction;
    skip_blank = List.mem skip `Blank;
    skip_nl = List.mem skip `Newline;
    skip_comment = List.mem skip `Comment;
  }

let in_range (t : t) pos =
  0 <= pos && pos < String.length t.contents

let get t pos =
  if in_range t pos then
    Some (String.get t.contents pos)
  else
    None

let end_of_line t =
  match get t t.pos with
  | None -> true
  | Some c -> Utils.is_newline c

let end_of_string t =
  not @@ in_range t t.pos

let can_skip_char t =
  function
  | ' ' -> t.skip_blank
  | '\t' -> t.skip_blank
  | '\r' -> t.skip_nl
  | '\n' -> t.skip_nl
  | _ -> false

let skip_comment (t : t) pos =
  match String.lfindi t.contents ~pos ~f:(fun _ c -> Utils.is_newline c) with
  | None -> String.length t.contents
  | Some pos' -> pos'

let scan t ~f =
  let step =
    match t.direction with
    | `Forward -> 1
    | `Backward -> -1
  in
  let rec scan' pos accu =
    match get t pos with
    | None -> accu
    | Some c ->
      if c = '-' && t.direction = `Forward && t.skip_comment &&
        get t (pos+1) = Some '-' then
        scan' (skip_comment t pos) accu
      else if can_skip_char t c then
        scan' (pos + step) accu
      else if f c then
        scan' (pos + step) (c :: accu)
      else
        accu
  in
  match scan' t.pos [] with
  | [] -> None
  | cs ->
    match t.direction with
    | `Forward ->
      t.pos <- t.pos + List.length cs;
      Some (String.of_char_list (List.rev cs))
    | `Backward ->
      t.pos <- t.pos - List.length cs;
      Some (String.of_char_list cs)

let scan_spaces t =
  scan t ~f:(fun c -> c = ' ')

let scan_newlines t =
  scan t ~f:(fun c ->
      match c with
      | '\r' -> true
      | '\n' -> true
      | _ -> false)

let scan_indent t =
  let indent =
    match scan t ~f:(fun c ->
        match c with
        | ' ' -> true
        | '\t' -> true
        | _ -> false) with
    | None -> Indent.zero
    | Some s -> Indent.create s
  in
  if end_of_line t then
    Some indent
  else
    None
