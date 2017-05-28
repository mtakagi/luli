open Core.Std

let get_opt s pos =
  try Some (String.get s pos) with _ -> None

let lines s =
  let rec split accu start pos =
    let slice pos = String.slice s start (pos + 1) in
    match get_opt s pos with
    | None -> List.rev accu
    | Some '\n' -> split (slice pos :: accu) (pos + 1) (pos + 1)
    | Some '\r' ->
      let pos' =
        match get_opt s (pos + 1) with
        | Some '\n' -> pos + 1
        | _ -> pos
      in
      split (slice pos' :: accu) (pos' + 1) (pos' + 1)
    | Some _ -> split accu start (pos + 1)
  in
  split [] 0 0

let drop_newlines =
  String.rstrip ~drop:(fun c -> c = '\r' || c = '\n')
