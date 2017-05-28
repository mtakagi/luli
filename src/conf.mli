open Core.Std

type lua_version =
  | Ver_5_1
  | Ver_5_2
  | Ver_5_3

val version : string
val proj_conf_name : string
val debug_mode : bool ref
val verbose_mode : bool ref

val lua_version : lua_version ref
val set_lua_version : string -> (lua_version, string) Result.t

val indent_size : int ref
val max_line_length : int ref
val max_num_errors : int ref
val selected_errors : string list ref
val ignored_errors : string list ref
val warns_to_error : string list ref
val makes_all_warns_to_errors : bool ref
val load_path : string list ref
val add_load_path : string list -> unit
val libraries : string list ref
val spell_check : bool ref
val autoload : bool ref
val first : bool ref
val anon_args : bool ref

val debug : ('a, out_channel, unit) format -> 'a
val verbose : ('a, out_channel, unit) format -> 'a
