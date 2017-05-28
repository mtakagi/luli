open Core.Std

type t = {
  path : string;
  contents : string;
  lines : (string * Location.t) array;
}

let create path =
  let contents = In_channel.input_all @@ In_channel.create path in
  let lines =
    let (_, accu) =
      List.foldi (Xstring.lines contents)
        ~init:(0, ([]:(string * Location.t) list))
        ~f:(fun lnum (offset, accu) line ->
            let col = String.length line in
            let offset' = offset + col in
            let loc =
              Location.create
                { Position.line = lnum; col = 0; offset = offset }
                { Position.line = lnum; col = col; offset = offset' }
            in
            (offset', (line, loc) :: accu))
    in
    List.to_array @@ List.rev accu
  in
  { path; contents; lines }

let offset t line col =
  Array.find_map t.lines
    ~f:(fun (_, loc) ->
        if loc.start.line = line &&
           loc.start.col <= col && col <= loc.end_.col then
          Some (loc.start.offset + (col - loc.start.col))
        else
          None)

let index t offset =
  Array.find_map t.lines
    ~f:(fun (_, loc) ->
        if Location.contains_offset loc offset then
          Some (loc.start.line, offset - loc.start.offset)
        else
          None)

let shift_pos t ~(pos:Position.t) ~len =
  let offset = pos.offset + len in
  match index t offset with
  | None -> None
  | Some (line, col) -> Some { Position.line; col; offset }

let shift_pos_exn t ~pos ~len =
  match shift_pos t ~pos ~len with
  | None -> raise (Invalid_argument "shift_pos_exn")
  | Some pos' -> pos'
