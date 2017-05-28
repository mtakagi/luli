type t = (string * (string * string) list) list

type parse_error = { pos : Lexing.position; error : string; }

