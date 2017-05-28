open Core.Std

module Var = struct

  type t = {
    name : string;
    loc : Location.t option;
    mutable used : bool;
    mutable global : bool;
  }

  let create ?loc name =
    { name = name;
      loc = loc;
      used = false;
      global = false;
    }

  let with_locd name =
    create ?loc:(Some name.Location.loc) name.Location.desc 

end


type t = {
  parent : t option;
  tbl : Var.t String.Table.t;
  spell : Var.t Spell_check.t;
}

let create parent =
  { parent = parent;
    tbl = String.Table.create ();
    spell = Spell_check.create ();
  }

let parent (env : t) =
  env.parent

let rec root (env : t) =
  match env.parent with
  | Some parent -> root parent
  | None -> env

let rec find_env ?(recur=true) (env : t) k =
  if Hashtbl.mem env.tbl k then
    Some env
  else if not recur then
    None
  else
    match env.parent with
    | Some parent -> find_env parent k
    | None -> None

let table (env : t) =
  env.tbl

let mem env k =
  match find_env env k with
  | Some _ -> true
  | None -> false

let find ?(recur=true) env k =
  match find_env ~recur env k with
  | Some e -> Hashtbl.find e.tbl k
  | None -> None

let set (env : t) (v : Var.t) =
  Hashtbl.set env.tbl ~key:v.name ~data:v;
  Spell_check.clear env.spell

let set_vargs env loc =
  let var = Var.create "..." ~loc in
  var.used <- true;
  set env var

let replace env (v : Var.t) =
  match find_env env v.name with
  | Some e -> set e v
  | None -> ()

let iter (env : t) f =
  Hashtbl.iteri env.tbl ~f:(fun ~key:_key ~data -> f data)

let global_common = [
  "_G"; "_VERSION";
  "assert"; "collectgarbage"; "dofile"; "error";
  "getmetatable"; "ipairs"; "load"; "loadfile"; "next"; "pairs";
  "pcall"; "print"; "rawequal"; "rawget"; "rawset"; "require"; "select";
  "setmetatable"; "tonumber"; "tostring"; "type"; "xpcall";
  "coroutine"; "debug"; "file"; "io"; "math"; "os"; "package"; "string"; "table";
]

let global_ver_5_1 = [
  "module"; "setfenv"; "getfenv"; "loadstring"; "unpack";
]

let global_ver_5_2 = [
  "_ENV"; "rawlen"; "bit32"; 
]

let global_ver_5_3 = [
  "_ENV"; "rawlen"; 
]

let global () =
  let data =
    List.concat [global_common;
                 begin match !Conf.lua_version with
                   | Ver_5_1 -> global_ver_5_1
                   | Ver_5_2 -> global_ver_5_2
                   | Ver_5_3 -> global_ver_5_3
                 end;
                ]
  in
  let (env : t) = create None in
  List.iter data ~f:(fun name -> set env (Var.create name));
  env

let rec suggest (env : t) s : Var.t option =
  match Spell_check.find_or_add env.spell s
          ~approx:(fun s ->
              match Spell_check.find_approx env.tbl s with
              | None -> None
              | Some s -> find env s) with
  | Some v -> Some v
  | None ->
    match env.parent with
    | None -> None
    | Some p -> suggest p s
