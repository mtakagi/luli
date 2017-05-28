{
open Lexing
open Parser

exception Syntax_error of string
exception Directive_error of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { pos with pos_bol = pos.pos_cnum;
               pos_lnum = pos.pos_lnum + 1
    }

let revise_pos pos lexbuf =
  Position.of_lexing_pos
    { pos with pos_lnum = pos.pos_lnum - 1;
               pos_bol = pos.pos_cnum - lexbuf.lex_curr_p.pos_bol }

let start_pos lexbuf =
  revise_pos (lexeme_start_p lexbuf) lexbuf

let end_pos lexbuf =
  revise_pos (lexeme_end_p lexbuf) lexbuf

let error lexbuf code =
  let loc = Location.create (start_pos lexbuf) (end_pos lexbuf) in
  Linterr.create lexbuf.lex_start_p.pos_fname loc code

let syntax_error lexbuf msg =
  error lexbuf @@ Linterr.Code.Syntax_error msg

let directive_error lexbuf msg =
  error lexbuf @@ Linterr.Code.Directive_error msg

let to_loc lexbuf =
  Location.create (start_pos lexbuf) (end_pos lexbuf)

let to_word lexbuf =
  { Location.desc = lexeme lexbuf; loc = to_loc lexbuf; }

let strlit_to_word lexbuf read =
  let sp = start_pos lexbuf in
  let s = read (Buffer.create 17) lexbuf in
  let loc = Location.create sp (end_pos lexbuf) in
  { Location.desc = s; loc = loc }

let long_comment_lv dir tag =
  let len = String.length tag in
  let diff = match dir with
  | `Begin -> 4
  | `End -> 2
  in
  len - diff

let long_string_lv tag =
  String.length tag - 2

}

let hex = '0' ['x' 'X']
let digit = ['0'-'9']
let hexdigit = ['0'-'9' 'a'-'f' 'A'-'F']
let int = digit+ | hex hexdigit+
let frac = '.' digit*
let exp = ['e' 'E'] ['-' '+']? digit+
let fnum = digit+ '.' digit* | ['.']? digit+
let hexfnum = hexdigit+ '.' hexdigit* | ['.']? hexdigit+
let binexp = ['p' 'P'] ['-' '+']? digit+
let float = fnum exp? | hex hexfnum binexp?
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let longcomment_begin = "--[" ['=']* '['
let longstr_begin = '[' ['=']* '['
let hexstr = '\\' 'x' hexdigit hexdigit
let octstr = '\\' digit? digit? digit?
let escape = '\\' ['\'' '"' '\\' 'a' 'b' 'f' 'n' 'r' 't' 'v']
let dqstrchr = escape | hexstr | octstr | [^ '"' '\\' '\r' '\n']+
let sqstrchr = escape | hexstr | octstr | [^ '\'' '\\' '\r' '\n']+
let longstrchr = escape | hexstr | octstr | [^ ']' '\\' '\r' '\n']+
let comment = "--"
let blank = [' ' '\t']*
let directive = comment blank "luli:" blank
let dirname = [^' ' '\t' '\r' '\n']+

rule read =
  parse
  | white       { read lexbuf }
  | newline     { next_line lexbuf; read lexbuf }
  | directive
    {
      let loc = to_loc lexbuf in
      let dir = read_directive lexbuf in
      Annot.add @@ { loc = loc; desc = Annot.Directive dir };
      next_line lexbuf;
      read lexbuf
    }
  | longcomment_begin as s
    { let sp = start_pos lexbuf in
      let lv = long_comment_lv `Begin s in
      let cnt = skip_long_comment lv (Buffer.create 17) lexbuf in
      let loc = Location.create sp (end_pos lexbuf) in
      Annot.add @@ { loc = loc;
                     desc = Annot.Comment { range = `Long; contents = cnt; }
                   };
      read lexbuf }
  | comment
    { let sp = start_pos lexbuf in
      let cnt = skip_comment (Buffer.create 17) lexbuf in
      let loc = Location.create sp (end_pos lexbuf) in
      Annot.add @@ { loc = loc;
                     desc = Annot.Comment { range = `Short; contents = cnt; }
                   };
      read lexbuf }
  | int         { NUMBER (to_word lexbuf) }
  | float       { NUMBER (to_word lexbuf) }
  | longstr_begin as s
    { let lv = long_string_lv s in
      LONG_STRING (strlit_to_word lexbuf (read_long_string lv)) }
  | '"'
    { DQUOTED_STRING (strlit_to_word lexbuf read_dquoted_string) }
  | '\''
    { SQUOTED_STRING (strlit_to_word lexbuf read_squoted_string) }
  | '{'         { LBRACE (to_loc lexbuf) }
  | '}'         { RBRACE (to_loc lexbuf) }
  | '['         { LBRACK (to_loc lexbuf) }
  | ']'         { RBRACK (to_loc lexbuf) }
  | '('         { LPAREN (to_loc lexbuf) }
  | ')'         { RPAREN (to_loc lexbuf) }
  | ':'         { COLON (to_loc lexbuf) }
  | "::"
    { if !Conf.lua_version <> Ver_5_2 then
        raise @@ Syntax_error "`::' is supported by Lua 5.2 or later"
      else
        DCOLON (to_loc lexbuf)
    }
  | ';'         { SEMI (to_loc lexbuf) }
  | ','         { COMMA (to_loc lexbuf) }
  | '.'         { DOT (to_loc lexbuf) }
  | ".."        { DOT2 (to_loc lexbuf) }
  | "..."       { DOT3 (to_loc lexbuf) }
  | '#'         { NSIGN (to_loc lexbuf) }
  | '>'         { LT (to_loc lexbuf) }
  | ">="        { LE (to_loc lexbuf) }
  | '<'         { GT (to_loc lexbuf) }
  | "<="        { GE (to_loc lexbuf) }
  | '='         { EQ (to_loc lexbuf) }
  | "=="        { EQQ (to_loc lexbuf) }
  | "~="        { NE (to_loc lexbuf) }
  | '+'         { ADD (to_loc lexbuf) }
  | '-'         { SUB (to_loc lexbuf) }
  | '*'         { MUL (to_loc lexbuf) }
  | '^'         { POW (to_loc lexbuf) }
  | '/'         { DIV (to_loc lexbuf) }
  | '%'         { REM (to_loc lexbuf) }
  | "and"       { AND (to_loc lexbuf) }
  | "or"        { OR (to_loc lexbuf) }
  | "not"       { NOT (to_loc lexbuf) }
  | "if"        { IF (to_loc lexbuf) }
  | "then"      { THEN (to_loc lexbuf) }
  | "elseif"    { ELSEIF (to_loc lexbuf) }
  | "else"      { ELSE (to_loc lexbuf) }
  | "end"       { END (to_loc lexbuf) }
  | "do"        { DO (to_loc lexbuf) }
  | "while"     { WHILE (to_loc lexbuf) }
  | "repeat"    { REPEAT (to_loc lexbuf) }
  | "until"     { UNTIL (to_loc lexbuf) }
  | "for"       { FOR (to_loc lexbuf) }
  | "in"        { IN (to_loc lexbuf) }
  | "function"  { FUNCTION (to_loc lexbuf) }
  | "local"     { LOCAL (to_loc lexbuf) }
  | "return"    { RETURN (to_loc lexbuf) }
  | "break"     { BREAK (to_loc lexbuf) }
  | "nil"       { NIL (to_loc lexbuf) }
  | "true"      { TRUE (to_loc lexbuf) }
  | "false"     { FALSE (to_loc lexbuf) }
  | "break"     { BREAK (to_loc lexbuf) }
  | "goto"
    { if !Conf.lua_version <> Ver_5_2 then
        IDENT (to_word lexbuf)
      else
        GOTO (to_loc lexbuf)
    }
  | id          { IDENT (to_word lexbuf) }
  | _           { raise (Syntax_error ("Unexpected char: " ^ lexeme lexbuf)) }
  | eof         { EOF (to_loc lexbuf) }

and skip_comment buf =
  parse
  | newline     { next_line lexbuf; Buffer.contents buf }
  | eof         { Buffer.contents buf }
  | _ as c      { Buffer.add_char buf c; skip_comment buf lexbuf }

and skip_long_comment lv buf =
  parse
  | ']' as c
    { Buffer.add_char buf c;
      skip_long_comment_end lv buf lexbuf }
  | newline as s
    { Buffer.add_string buf s;
      next_line lexbuf;
      skip_long_comment lv buf lexbuf }
  | eof
    { raise (Syntax_error ("Long comment is not terminated")) }
  | _ as c
    { Buffer.add_char buf c;
      skip_long_comment lv buf lexbuf }

and skip_long_comment_end lv buf =
  parse
  | ']' as c
    { if lv <> 0 then begin
        Buffer.add_char buf c;
        skip_long_comment lv buf lexbuf
      end else
        Buffer.contents buf
    }
  | ['=']+ as s
    { if String.length s = lv then
        skip_long_comment_end' lv buf s lexbuf
      else
        skip_long_comment lv buf lexbuf
    }
  | newline as s
    { Buffer.add_string buf s; 
      next_line lexbuf;
      skip_long_comment lv buf lexbuf }
  | eof
    { raise (Syntax_error ("Long comment is not terminated")) }
  | _ as c
    { Buffer.add_char buf c;
      skip_long_comment lv buf lexbuf }

and skip_long_comment_end' lv buf last =
  parse
  | ']'
    { Buffer.contents buf }
  | newline as s
    { Buffer.add_string buf last;
      Buffer.add_string buf s;
      next_line lexbuf;
      skip_long_comment lv buf lexbuf }
  | eof
    { raise (Syntax_error ("Long comment is not terminated")) }
  | _ as c
    { Buffer.add_string buf last;
      Buffer.add_char buf c;
      skip_long_comment lv buf lexbuf }

and read_dquoted_string buf =
  parse
  | '"'       { Buffer.contents buf }
  | newline as s
    { Buffer.add_string buf s;
      next_line lexbuf;
      read_dquoted_string buf lexbuf }
  | dqstrchr as s
    { Buffer.add_string buf s; read_dquoted_string buf lexbuf }
  | _ { raise (Syntax_error ("Illegal string character: " ^ lexeme lexbuf)) }
  | eof { raise (Syntax_error ("String is not terminated")) }

and read_squoted_string buf =
  parse
  | '\''      { Buffer.contents buf }
  | newline as s
    { Buffer.add_string buf s;
      next_line lexbuf;
      read_squoted_string buf lexbuf }
  | sqstrchr as s
    { Buffer.add_string buf s; read_squoted_string buf lexbuf }
  | _ { raise (Syntax_error ("Illegal string character: " ^ lexeme lexbuf)) }
  | eof { raise (Syntax_error ("String is not terminated")) }

and read_long_string lv buf =
  parse
  | ']'
  {
    Buffer.add_char buf ']';
    read_long_string_end lv buf lexbuf
  }
  | newline as s
  {
    next_line lexbuf;
    Buffer.add_string buf s;
    read_long_string lv buf lexbuf
  }
  | longstrchr as s { Buffer.add_string buf s; read_long_string lv buf lexbuf }
  | _ { raise (Syntax_error ("Illegal string character: " ^ lexeme lexbuf)) }
  | eof { raise (Syntax_error ("Long string is not terminated")) }

and read_long_string_end lv buf =
  parse
  | ']'
  {
    if lv = 0 then
      Core.Std.String.drop_suffix (Buffer.contents buf) (lv+1)
    else
      read_long_string lv buf lexbuf
  }
  | ['=']+ as s
  {
    Buffer.add_string buf s;
    if String.length s = lv then
      read_long_string_end' lv buf lexbuf
    else
      read_long_string lv buf lexbuf
  }
  | newline as s
  {
    next_line lexbuf;
    Buffer.add_string buf s;
    read_long_string lv buf lexbuf
  }
  | longstrchr as s { Buffer.add_string buf s; read_long_string lv buf lexbuf }
  | _ { raise (Syntax_error ("Illegal string character: " ^ lexeme lexbuf)) }
  | eof { raise (Syntax_error ("Long string is not terminated")) }

and read_long_string_end' lv buf =
  parse
  | ']'
  { Buffer.contents buf }
  | newline as s
  {
    next_line lexbuf;
    Buffer.add_string buf s;
    read_long_string lv buf lexbuf
  }
  | longstrchr as s { Buffer.add_string buf s; read_long_string lv buf lexbuf }
  | _ { raise (Syntax_error ("Illegal string character: " ^ lexeme lexbuf)) }
  | eof { raise (Syntax_error ("Long string is not terminated")) }

and read_directive =
  parse
  | "noqa" blank newline { Noqa }
  | (dirname as s) [^'\r' '\n']* newline
    { raise (Directive_error (Core.Std.sprintf "unknown directive `%s'" s)) }
  | [^'\r' '\n']* newline
    { raise (Directive_error "empty directive") }

(* This is to skip the first line start with '#' *)
and skip_sharp = parse
  | "#" [^ '\n']* '\n' { next_line lexbuf }
  | "" { () }
