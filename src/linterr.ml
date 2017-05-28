open Core.Std

include Linterr_internal

type t = {
  path : string;
  loc : Location.t;
  code : Code.t;
}

let create path loc code =
  { path; loc; code }

let num (err : t) =
  Code.num err.code

let tag (err : t) =
  Code.tag err.code

let loglv (err : t) =
  Code.loglv err.code

let loglv_tag (err : t) =
  LogLv.tag @@ loglv err

let is_warn (err : t) =
  loglv (err : t) = LogLv.Warn

let message (err : t) =
  Code.message err.code

let contains_warn (errs : t list) =
  List.exists errs ~f:is_warn

let contains_error (errs : t list) =
  let base = LogLv.to_int LogLv.Error in
  List.exists errs ~f:(fun e -> LogLv.to_int (loglv e) <= base)

let file_errors (errs : t list) path =
  List.filter errs ~f:(fun e -> e.path = path)

let sort (errs : t list) =
  List.sort ~cmp:(fun a b -> compare a.loc.start.offset b.loc.start.offset) errs

let filter_first (errs : t list) =
  List.rev @@ List.fold errs ~init:[]
    ~f:(fun accu e ->
          if List.exists accu ~f:(fun e' -> tag e = tag e') then
            accu
          else
            e :: accu)
 

