open Core.Std

type lua_version =
  | Ver_5_1
  | Ver_5_2
  | Ver_5_3

let version = "1.0.0"
let proj_conf_name = "Lulifile"
let debug_mode = ref false
let verbose_mode = ref false
let lua_version = ref Ver_5_3
let indent_size = ref 2
let max_line_length = ref 79
let max_num_errors = ref 0
let selected_errors = ref []
let ignored_errors = ref []
let warns_to_error = ref []
let makes_all_warns_to_errors = ref false
let load_path = ref ["."]
let libraries = ref []
let spell_check = ref true
let autoload = ref true
let first = ref false
let anon_args = ref false

let debug f =
  if !debug_mode then
    printf ("# " ^^ f ^^ "\n")
  else
    Printf.ifprintf stderr f

let verbose f =
  if !verbose_mode || !debug_mode then
    printf ("# " ^^ f ^^ "\n")
  else
    Printf.ifprintf stderr f

let set_lua_version v =
  let res = match v with
    | "5.1" -> Result.Ok Ver_5_1
    | "5.2" -> Ok Ver_5_2
    | "5.3" -> Ok Ver_5_3
    | _ -> Error (Printf.sprintf "invalid Lua version %s" v)
  in
  Result.iter res ~f:(fun ver -> lua_version := ver);
  res

let add_load_path paths =
  let paths' = List.map paths ~f:(fun path -> Utils.normpath path) in
  load_path := List.concat [paths'; !load_path]
