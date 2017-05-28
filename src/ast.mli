open Ast_types

module AstUnaryOp : sig
  type t = unop
  val to_string : unop -> string
end

module AstBinOp : sig
  type t = binop
  val to_string : binop -> string
end

module AstOp : sig
  type t = op
  val to_string : op -> string
end

module AstDump : sig
  type t
  val name : t -> string
  val of_ast : ast -> t
  val printi : out_channel -> int -> t -> unit
  val print : out_channel -> t -> unit
end

module FuncBody : sig
  type t = funcbody
  val arity : t -> int
  val parlist : t -> parlist option
  val vargs : t -> [> `Fixed_args | `Var_args ]
end

module Parlist : sig
  type t = parlist
  val params : t -> word list option * ellipsis option
  val last_elt_loc : t -> Location.t
end

type t = ast

val dump : t -> unit
val unwrap : t -> t
val is_true_cond : t -> bool
val is_false_cond : t -> bool
val is_zero : t -> bool
