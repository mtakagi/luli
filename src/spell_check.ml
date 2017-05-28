open Core.Std

type 'a t = [`Found of 'a | `Not_found] String.Table.t

let create () =
  String.Table.create ()

let distance =
  Levenshtein.String.distance

let find dict s =
  match Hashtbl.find dict s with
  | Some (`Found v) -> Some v
  | Some `Not_found -> None
  | None -> None

let find_or_add dict s ~approx =
  match Hashtbl.find dict s with
  | Some (`Found v) -> Some v
  | Some `Not_found -> None
  | None ->
    match approx s with
    | None ->
      Hashtbl.set dict ~key:s ~data:`Not_found;
      None
    | Some v as opt ->
      Hashtbl.set dict ~key:s ~data:(`Found v);
      opt

let find_approx ?(range=2) tbl s : string option =
  let len = String.length s in
  let upper_bound = len + range in
  let accu =
    Hashtbl.fold tbl
      ~init:None
      ~f:(fun ~key ~data:_ accu ->
        let len' = String.length key in
        if len - range > len' || len + range < len' then
          accu
        else begin
          match accu with
          | Some (0, _) -> accu
          | Some (score, _) ->
            let score' = distance ~upper_bound s key in
            if score' <= range && score' < score then
              Some (score', key)
            else
              accu
          | None ->
            let score = distance ~upper_bound s key in
            if score <= range then
              Some (score, key)
            else
              None
        end)
  in
  match accu with
  | Some (_, key) -> Some key
  | None -> None

let clear =
  Hashtbl.clear
