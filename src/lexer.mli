exception Syntax_error of string
exception Directive_error of string

val skip_sharp : Lexing.lexbuf -> unit
(** 行頭が "#" で始まっていれば、その行を読み飛ばす *)

val read : Lexing.lexbuf -> Parser.token
(** 字句解析のエントリーポイント *)

val syntax_error : Lexing.lexbuf -> string -> Linterr.t
(** 文法エラーを示すエラーコードを生成する *)

val directive_error : Lexing.lexbuf -> string -> Linterr.t
(** ディレクティブエラーを示すエラーコードを生成する *)
