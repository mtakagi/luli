open Core.Std

type module_ = {
  name : string;
  path : string;
  loc : Location.t;
  status : [`Loading | `Loaded];
}

type t = {
  loaded : module_ String.Table.t;
  mutable loading : module_ list;
}

let create () =
  { loaded = String.Table.create ();
    loading = [];
  }

let find t ~name =
  match String.Table.find t.loaded name with
  | Some m -> Some m
  | None -> List.find t.loading ~f:(fun m -> m.name = name)

let loading t ~name ~path ~loc =
  let m = { name = name; path = path; loc = loc; status = `Loading }
  in
  t.loading <- m :: t.loading

let finish_loading t =
  match t.loading with
  | [] -> failwith "loading modules are none"
  | m :: rest ->
    let m' = { m with status = `Loaded } in
    String.Table.set t.loaded ~key:m'.name ~data:m';
    t.loading <- rest

let trace t =
  List.map t.loading ~f:(fun m -> m.loc)
