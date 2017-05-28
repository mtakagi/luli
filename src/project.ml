open Core.Std
open Conf

let complete_suffix path =
  if String.is_suffix path ~suffix:".lua" then
    path
  else
    path ^ ".lua"

let find_lib_path path =
  let path' = Utils.modname_to_path path |> Utils.normpath |> complete_suffix in
  let paths = path' :: (List.map !load_path
                          ~f:(fun dir -> Filename.concat dir path'))
  in
  List.find paths
    ~f:(fun p ->
        verbose "find module \"%s\"" p;
        match Sys.file_exists p ~follow_symlinks:true with
        | `Yes -> true
        | _ -> false)

let find_proj_conf basedir =
  let rec get_paths dir accu =
    let accu' = Filename.concat dir proj_conf_name :: accu in
    if dir = Filename.root then
      List.rev accu'
    else
      let (parent, _) = Filename.split dir in
      get_paths parent accu'
  in
  let paths = get_paths basedir [] in
  let res = List.find paths ~f:(fun path ->
      verbose "find Lulifile \"%s\"" path;
      match Sys.file_exists path with
      | `Yes -> true
      | _ -> false)
  in
  begin match res with
    | Some _ -> verbose "Lulifile found"
    | None -> verbose "Lulifile not found"
  end;
  res

let is_noqa_error (err : Linterr.t) =
  List.exists (Annot.annots ())
    ~f:(fun d -> d.desc = Annot.(Directive Noqa) &&
                 err.loc.start.line = d.loc.start.line)

let filter_error (err : Linterr.t) ~fname =
  if is_noqa_error err then
    false
  else if fname <> err.path then
    false
  else begin
    let err_tag = Linterr.tag err in
    let lv_tag = Linterr.loglv_tag err in
    let f e = e = err_tag || e = lv_tag in
    if not @@ List.is_empty !selected_errors then
      List.exists !selected_errors ~f
    else
      not @@ List.exists !ignored_errors ~f
  end

let filter_errors errs ~fname =
  List.filter errs ~f:(filter_error ~fname)

let contains_warns_to_error errs =
  let rec check = function
    | [] -> false
    | err :: errs ->
      if Linterr.is_warn err then begin
        if !makes_all_warns_to_errors then
          true
        else begin
          if List.exists !warns_to_error
              ~f:(fun w -> w = Linterr.tag err) then
            true
          else
            check errs
        end
      end else
        check errs
  in
  if List.is_empty errs then
    false
  else
    check errs

let contains_error errs =
  Linterr.contains_error errs || contains_warns_to_error errs

let set_config k v =
  with_return
    (fun r ->
       begin match k with
         | "debug" -> debug_mode := Bool.of_string v
         | "verbose" -> verbose_mode := Bool.of_string v
         | "lua-version" ->
           r.return (Result.map (set_lua_version v) ~f:(fun _ver -> ()))
         | "select" -> selected_errors := Ini.value_to_list v
         | "ignore" -> ignored_errors := Ini.value_to_list v
         | "max-line-length" -> max_line_length := Int.of_string v
         | "L" -> add_load_path @@ Ini.value_to_list v
         | "l" -> libraries := Ini.value_to_list v
         | "limit" -> max_num_errors := Int.of_string v
         | "warn-error" -> warns_to_error := Ini.value_to_list v
         | "warn-error-all" -> makes_all_warns_to_errors := Bool.of_string v
         | "spell-check" -> spell_check := Bool.of_string v
         | "autoload" -> autoload := Bool.of_string v
         | "first" -> first := Bool.of_string v
         | "anon-args" -> anon_args := Bool.of_string v
         | _ -> r.return (Error (Printf.sprintf "invalid item %s" k))
       end;
       Ok ())

let load path =
  with_return (fun r ->
      match Sys.file_exists path with
      | `Yes ->
        begin match Ini.read path with
          | Success ini ->
            if Ini.mem_section ini "luli" then begin
              Ini.iter ini "luli"
                (fun k v -> Result.iter_error (set_config k v)
                    ~f:(fun msg -> r.return (Result.Error msg)))
            end else begin
              printf "%s: warning: section `luli' is not found\n" path;
            end;
            Ok ()
          | Failure e ->
            Error (sprintf "%s:%d:%d: %s" e.pos.pos_fname
                     e.pos.pos_lnum e.pos.pos_bol e.error)
        end
      | _ ->
        Error (sprintf "no such config file `%s'" path))

let init_proj_conf () =
  let lines = [
    "[luli]";
    "; デバッグモード";
    "; debug = true";
    "";
    "; 詳細メッセージの表示";
    "; verbose = true";
    "";
    "; Lua のバージョン (5.1, 5.2)";
    "; lua-version = 5.2";
    "";
    "; 指定したエラーコードのみを表示する";
    "; select = E";
    "";
    "; 指定したエラーコードを表示しない";
    "; ignore = E, W";
    "; ignore = E261, E701, W302, W303";
    "";
    "; 一行の文字数";
    "; max-line-length = 79";
    "";
    "; 表示するエラーの最大数";
    "; limit = 30";
    "";
    "; 指定した警告をエラーとして扱う";
    "; warn-error = W292, W293, W391";
    "";
    "; すべての警告をエラーとして扱う";
    "; warn-error-all = true";
    "";
    "; スペルチェックを行わない";
    "; spell-check = false";
    "";
    "; ライブラリのロードパス";
    "; L = /usr/lib/lua, /usr/local/lib/lua";
    "";
    "; require で指定されているライブラリをロードする";
    "; autoload = false";
    "";
    "; 指定したライブラリを解析前にロードする";
    "; l = mylib";
    "";
    "; 検出されたそれぞれのエラーコードのうち、最初に現れた結果のみを表示する";
    "; first = true";
    "";
    "; 名前が '_' で始まる引数に対して未使用の警告を行わない";
    "; anon-args = true";
  ] in
  String.concat lines ~sep:"\n"
