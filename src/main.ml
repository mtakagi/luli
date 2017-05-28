open Core.Std

let validator_handlers =
  [Validator_blank_lines.f;
   Validator_line_length.f;
   Validator_comments.f;
   Validator_spaces.f;
   Validator_vars.f;
   Validator_strings.f;
   Validator_stats.f;
   Validator_deadcode.f;
   Validator_parens.f;
   Validator_indents.f;
   Validator_lua_types.f;
  ]

let version () =
  sprintf "luli %s" Conf.version

let create_proj_conf () =
  match Sys.file_exists Conf.proj_conf_name with
  | `No ->
    printf "# creating %s\n" Conf.proj_conf_name;
    Out_channel.write_all Conf.proj_conf_name ~data:(Project.init_proj_conf ());
    exit 0
  | _ ->
    printf "error: %s already exists\n" Conf.proj_conf_name;
    exit 1

let print_result errs =
  let limit =
    !Conf.max_num_errors > 0 && List.length errs > !Conf.max_num_errors
  in
  let filters = [
    Linterr.sort;
    (fun errs ->
       match limit with
       | true -> List.sub errs ~pos:0 ~len:!Conf.max_num_errors
       | false -> errs);
    (fun errs ->
       if !Conf.first then
         Linterr.filter_first errs
       else
         errs);
  ] in
  let filtered = List.fold filters ~init:errs ~f:(fun errs f -> f errs) in
  List.iter filtered ~f:(fun err ->
      let s = err.loc.start in
      printf "%s:%d:%d: %s %s\n" err.path (s.line + 1) (s.col + 1)
        (Linterr.tag err) (Linterr.message err));

  let len = List.length errs in
  let rest = len - !Conf.max_num_errors in
  if limit && rest > 0 then
    printf "... and more %d errors and warnings\n" rest;
  Conf.verbose "found %d errors and warnings" len;

  if Project.contains_error errs then
    exit (-1)
  else
    exit 0

let run file =
  Conf.verbose "load path:";
  List.iter !Conf.load_path
    ~f:(fun path -> Conf.verbose "    %s" path);

  let vld = Validator.create ~handlers:validator_handlers in
  begin try
      List.iter !Conf.libraries
        ~f:(fun name ->
            match Project.find_lib_path name with
            | None ->
              printf "error: library not found - %s\n" name;
              exit (-1)
            | Some path ->
              match Validator.load vld path with
              | `Success _ ->
                ()
              | `Failure ->
                printf "error: failed loading module `%s'\n" name;
                exit (-1));
      Conf.verbose "validate \"%s\"" file;
      Validator.validate vld file;
    with
    | Validator.Load_error (msg, trace)->
      printf "error: %s\n" msg;
      List.iter trace
        ~f:(fun loc -> printf "    %s: %d\n" file loc.start.line);
      exit (-1)
  end;

  let errs = Project.filter_errors (Validator.errors vld) ~fname:file in
  print_result errs

let get_os_version () =
  let (l, _) = Utils.exec_cmd "uname -a" in
  if List.length l > 0 then
    List.hd_exn l
  else
    "unknown"

let get_envs () =
  let names = ["OCAMLPARAM"; "OCAMLRUNPARAM"; "CAMLRUNPARAM"] in
  String.concat ~sep:"\n" @@
  List.map names ~f:(fun name ->
      sprintf "%s = %s" name (match Sys.getenv name with
          | None -> ""
          | Some v -> v))

let crash_dump e =
  let items = [
    ("Date", Time.to_string @@ Time.now ());
    ("Version", version ());
    ("OS", get_os_version ());
    ("Environment variables", get_envs ());
    ("Command", String.concat_array ~sep:" " Sys.argv);
    ("Exception", Exn.to_string e);
    ("Trace", Printexc.get_backtrace ())]
  in
  String.concat ~sep:"\n\n"
    (List.map items ~f:(fun (title, desc) ->
         match String.split_lines desc with
         | [line] -> sprintf "%s: %s" title line
         | lines ->
           sprintf "%s:\n%s" title
             (String.concat ~sep:"\n" @@ List.map lines
                ~f:(fun s -> sprintf "    %s" s))))

let generate_crash_file e =
  let pid = Pid.to_int @@ Unix.getpid () in
  let fname = sprintf "luli.%d.dump" pid in
  Out_channel.write_all fname ~data:(crash_dump e);
  printf "fatal error: this program is crashed (dump into %s).\n" fname;
  exit (-1)

let set_conf_options ~debug ~verbose ~lua_version ~select ~ignore
    ~max_line_length ~limit ~config ~warn_error ~warn_error_all
    ~load_path ~libs ~no_spell_check ~no_autoload ~first ~anon_args =
  with_return
    (fun r ->
       Conf.debug_mode := debug;
       Conf.verbose_mode := verbose;
       Option.iter lua_version
         ~f:(fun s -> Result.iter_error (Conf.set_lua_version s)
                ~f:(fun msg -> r.return (Result.Error msg)));
       Option.iter select
         ~f:(fun errs -> Conf.selected_errors := Ini.value_to_list errs);
       Option.iter ignore
         ~f:(fun errs -> Conf.ignored_errors := Ini.value_to_list errs);
       Option.iter max_line_length ~f:(fun len -> Conf.max_line_length := len);
       Option.iter limit ~f:(fun n -> Conf.max_num_errors := n);
       Option.iter warn_error
         ~f:(fun warns -> Conf.warns_to_error := Ini.value_to_list warns);
       Conf.makes_all_warns_to_errors := warn_error_all;
       Conf.add_load_path load_path;
       Conf.libraries := libs;
       Conf.spell_check := not no_spell_check;
       Conf.autoload := not no_autoload;
       Conf.first := first;
       Conf.anon_args := anon_args;

       (* -config or Lulifile *)
       let config' =
         match config with
         | None -> Project.find_proj_conf @@ Sys.getcwd ()
         | Some _ -> config
       in
       begin match config' with
         | None -> ()
         | Some path ->
           Result.iter_error (Project.load path)
             ~f:(fun msg -> r.return (Error msg));
           (* Lulifile のあるパスをロードパスに追加 *)
           Conf.add_load_path [Filename.dirname path]
       end;
       Ok ())

let command =
  Command.basic
    ~summary: "luli: Lua static analysis tool by Shiguredo Inc."
    Command.Spec.(
      empty
      +> flag "-d" no_arg ~doc:" debug output from parser"
      +> flag "-v" no_arg ~doc:" print verbose message"
      +> flag "-lua-version" (optional string)
        ~doc:" target version of Lua [5.1, 5.2, 5.3] (default: 5.3)"
      +> flag "-init" no_arg
        ~doc:" create project config file (Lulifile) into the current directory"
      +> flag "-select" (optional string) ~doc:" select errors and warnings (e.g. E,W,W4)"
      +> flag "-ignore" (optional string) ~doc:" skip errors and warnings (e.g. E,W,W4)"
      +> flag "-max-line-length" (optional int) ~doc:" set maximum allowed line length (default: 79)"
      +> flag "-limit" (optional int) ~doc:" set maximum allowed errors and warnings"
      +> flag "-config" (optional string)
        ~doc:(" config file. if this option not specified," ^
              " luli tries to find a directory that has \"" ^
              Conf.proj_conf_name ^ "\"")
      +> flag "-warn-error" (optional string)
        ~doc:" make warnings into errors (e.g. 4,37,123)"
      +> flag "-warn-error-all" no_arg
        ~doc:" make all warnings into errors"
      +> flag "-L" (listed string) ~doc:" library load path"
      +> flag "-l" (listed string) ~doc:" load (require) the library before the script"
      +> flag "-no-spell-check" no_arg ~doc:" disable spell checking"
      +> flag "-no-autoload" no_arg
        ~doc:" disable loading libraries specified by \"require()\" on top level"
      +> flag "-first" no_arg ~doc:" show first occurrence of each error"
      +> flag "-anon-args" no_arg
        ~doc:" do not produce `unused variable' warnings for arguments which name begins with `_'"
      +> anon (maybe ("filename" %: string))
    )
    (fun debug verbose lua_version init_conf
      select ignore max_line_length limit config
      warn_error warn_error_all load_path libs no_spell_check
      no_autoload first anon_args filename () ->
      try
        Printexc.record_backtrace true;

        begin match
            set_conf_options
              ~debug ~verbose ~lua_version ~select ~ignore
              ~max_line_length ~limit ~config ~warn_error ~warn_error_all
              ~load_path ~libs ~no_spell_check ~no_autoload ~first ~anon_args
          with
          | Ok () -> ()
          | Error msg ->
            printf "error: %s\n" msg;
            exit 1
        end;

        if init_conf then
          create_proj_conf ()
        else begin
          match filename with
          | None ->
            printf "Usage: luli [options] FILENAME\n\n";
            printf "error: input not specified\n";
            exit 1
          | Some filename' ->
            match Sys.file_exists filename' with
            | `Yes -> run filename'
            | _ ->
              printf "error: no such file `%s'\n" filename';
              exit (-1)
        end
      with
      | e -> generate_crash_file e)

let () =
  Command.run ~version:(version ()) ~build_info:"Shiguredo Inc." command
