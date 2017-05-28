open Core.Std

type t = {
  line_type : line_type;
  start : int;
  end_ : int;
  depth : int;
  mutable children : t list;
}

and line_type =
  | Logical_line
  | Cont_line of cont * close

and cont =
  | Visual
  | Hanging

and close =
  | Trailing
  | New_line

let create ~line_type ~start ~end_ ~depth =
  { line_type; start; end_; depth; children = [] }

let line_typeains_range t ~start ~end_ =
  t.start <= start && end_ <= t.end_

let line_typeains_line t ~lnum =
  line_typeains_range t ~start:lnum ~end_:lnum

let is_logical_line t =
  match t.line_type with
  | Logical_line -> true
  | Cont_line _ -> false

let is_cont_line t =
  not @@ is_logical_line t

let root =
  ref @@ create ~line_type:Logical_line ~start:0 ~end_:10000000 ~depth:0

let find ~f =
  let rec find' t =
    if f t then
      match List.find t.children ~f with
      | None -> Some t
      | Some t' -> find' t'
    else
      None
  in
  find' !root

let find_range ~start ~end_ =
  find ~f:(line_typeains_range ~start ~end_)

let find_lnum ~lnum =
  find ~f:(line_typeains_line ~lnum)

let add ~line_type ~start ~end_ ~depth =
  match find_range ~start ~end_ with
  | None -> failwith "add"
  | Some parent ->
    let t = create ~line_type ~start ~end_ ~depth in
    parent.children <- t :: parent.children
