open Core.Std

type t = (string * (string * string) list) list

type parse_error = Ini_type.parse_error =
  { pos : Lexing.position; error : string; }

type parse_result =
  | Success of t
  | Failure of parse_error

module Parser = Ini_parser
module Lexer = Ini_lexer

let read file =
  let inx = In_channel.create file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.Lexing.lex_curr_p <-
    { lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = file };
  try begin
    Success (Parser.main Lexer.main lexbuf)
  end with
  | Lexer.Syntax_error msg -> Failure (Lexer.syntax_error lexbuf msg)
  | Parser.Error -> Failure (Lexer.syntax_error lexbuf "invalid syntax")

let sections t =
  List.map t ~f:(fun (sec, _) -> sec)

let options t sec =
  match List.find t ~f:(fun (sec', _) -> sec = sec') with
  | Some (_, opts) -> Some opts
  | None -> None

let mem_section t sec =
  is_some @@ options t sec

let get t sec opt =
  match options t sec with
  | Some opts ->
    begin match List.find opts ~f:(fun (k, _) -> k = opt) with
    | Some (_, v) -> Some v
    | None -> None
    end
  | None -> None

let mem_option t sec opt =
  is_some @@ get t sec opt

let iter (t : t) sec f =
  match options t sec with
  | Some opts -> List.iter opts ~f:(fun (k, v) -> f k v)
  | None -> ()

let value_to_list ?(on=',') s =
  List.map (String.split ~on s)
    ~f:(fun s' -> String.strip s' ~drop:(fun c -> c = ' '))
