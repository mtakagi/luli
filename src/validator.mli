exception Load_error of string * Location.t list

type t

type event =
  | Validate_file of (t * Context.t * File.t)
  | Validate_env_begin of (t * Context.t * Env.t)
  | Validate_env_end of (t * Context.t * Env.t)
  | Validate_ast_begin of (t * Context.t * Ast_types.ast)
  | Validate_ast_end of (t * Context.t * Ast_types.ast)
  | Validate_chunk_begin of (t * Context.t * Ast_types.chunk)
  | Validate_chunk_end of (t * Context.t * Ast_types.chunk)
  | Validate_funcbody_begin of (t * Context.t * Ast_types.funcbody)
  | Validate_funcbody_end of (t * Context.t * Ast_types.funcbody)

  (* インデント管理のロジックを書き直したら不要になるかも *)
  | Validate_cont_line_end of (t * Context.t * Location.t * Location.t)

val create : handlers:(event -> unit) list -> t

val load : t -> string ->
  [`Success of Linterr.t list | `Failure]
(** ライブラリをロードする。検査エラーは記録されない *)

val loading : t -> Loading.t

val validate : t -> string -> unit

val errors : t -> Linterr.t list
