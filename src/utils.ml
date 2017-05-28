open Core.Std

let sep = '/'

let is_newline = function
  | '\r' -> true
  | '\n' -> true
  | _ -> false

let join ?(sep=", ") es =
  String.concat es ~sep

let normpath path =
  match Sys.getenv "HOME" with
  | None -> path
  | Some home ->
    let comps = String.split path ~on:'~' in
    String.concat comps ~sep:home

let modname_to_path path =
  match String.split path ~on:'.' with
  | [] -> failwith "Conf.modname_to_path"
  | [_] -> path
  | x :: xs ->
    List.fold xs ~init:[x]
      ~f:(fun accu comp ->
          if comp = "" || comp = "lua" || String.is_prefix comp ~prefix:"/" then
            ("." ^ comp) :: accu
          else
            (String.of_char sep ^ comp) :: accu)
    |> List.rev |> String.concat ~sep:""

let exec_cmd cmd =
  let rec read inx accu =
    try
      let line = input_line inx in
      read inx @@ line :: accu
    with
    | End_of_file -> (List.rev accu, Unix.close_process_in inx)
  in
  read (Unix.open_process_in cmd) []

let seplist_to_loc (l : ('a, 'b) Seplist.t)
      ~(fa : ('a -> Location.t)) ~(fb : ('b -> Location.t)) =
  let e = Seplist.hd l in
  match Seplist.tl l with
  | None -> Location.with_loc (fa e) l
  | Some es ->
    let end_ = match Seplist.last es with
    | A e' -> fb e'
    | B e' -> fa e'
    in
    Location.with_range (fa e) end_ l

let delim_seplist_to_loc l =
  seplist_to_loc
    ~fa:(fun t -> t.Location.loc) ~fb:(fun t -> t) @@
      Seplist.of_a_rev @@ Seplist.rev l
