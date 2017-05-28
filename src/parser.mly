%{

open Ast_types
open Location

let make_unexp op op_loc exp =
  let desc = Unary_expr (Location.with_loc op_loc op, exp) in
  with_range op_loc exp.loc desc

let make_binexp left op op_loc right =
  let binop = Location.with_loc op_loc op in
  let desc = Bin_expr (left, binop, right) in
  with_range left.loc right.loc desc

let make_if conds elsecond end_loc =
  let { Location.loc = start_loc } = Core.Std.List.hd_exn conds in
  with_range start_loc end_loc (If (conds, elsecond, end_loc)) 

let make_parenexp lp exp rp =
  with_range lp rp (Paren_expr (lp, exp, rp))

let nop t =
  Location.with_loc t (Nop t)

let block_loc block default =
  match block with
  | None -> default
  | Some block_val -> block_val.loc

%}

%token <Ast_types.word> IDENT
%token <Ast_types.word> SQUOTED_STRING
%token <Ast_types.word> DQUOTED_STRING
%token <Ast_types.word> LONG_STRING
%token <Ast_types.word> NUMBER
%token <Location.t> LPAREN
%token <Location.t> RPAREN
%token <Location.t> LBRACK
%token <Location.t> RBRACK
%token <Location.t> LBRACE
%token <Location.t> RBRACE
%token <Location.t> COMMA
%token <Location.t> DOT
%token <Location.t> DOT2             (* ".." *)
%token <Location.t> DOT3             (* "..." *)
%token <Location.t> COLON
%token <Location.t> DCOLON
%token <Location.t> SEMI
%token <Location.t> NSIGN            (* "#" *)
%token <Location.t> AND              (* "and" *)
%token <Location.t> OR               (* "or" *)
%token <Location.t> NOT              (* "not" *)
%token <Location.t> EQ               (* "=" *)
%token <Location.t> EQQ              (* "==" *)
%token <Location.t> NE               (* "~=" *)
%token <Location.t> LT
%token <Location.t> LE
%token <Location.t> GT
%token <Location.t> GE
%token <Location.t> ADD              (* "+" *)
%token <Location.t> SUB              (* "-" *)
%token <Location.t> MUL              (* "*" *)
%token <Location.t> DIV              (* "/" *)
%token <Location.t> REM              (* "%" *)
%token <Location.t> POW              (* "^" *)
%token <Location.t> END              (* "end" *)
%token <Location.t> IF               (* "if" *)
%token <Location.t> IN               (* "in" *)
%token <Location.t> ELSEIF           (* "elseif" *)
%token <Location.t> ELSE             (* "else" *)
%token <Location.t> THEN             (* "then" *)
%token <Location.t> DO               (* "do" *)
%token <Location.t> FOR              (* "for" *)
%token <Location.t> FUNCTION         (* "function" *)
%token <Location.t> LOCAL            (* "local" *)
%token <Location.t> RETURN           (* "return" *)
%token <Location.t> BREAK            (* "break" *)
%token <Location.t> WHILE            (* "while" *)
%token <Location.t> REPEAT           (* "repeat" *)
%token <Location.t> UNTIL            (* "until" *)
%token <Location.t> NIL              (* "nil" *)
%token <Location.t> FALSE            (* "false" *)
%token <Location.t> TRUE             (* "true" *)
%token <Location.t> GOTO             (* "goto" *)
%token <Location.t> EOF

%left OR AND LT GT LE GE NE EQQ
%right DOT2
%left  ADD SUB MUL DIV REM NOT NSIGN
%right POW

%nonassoc app
%nonassoc LPAREN

%start <Ast_types.ast> prog

%%

prog:
  | chunk EOF
  { match $1 with
    | None -> with_range $2 $2 (Prog (None ,$2))
    | Some v -> with_range v.loc $2 (Prog ($1, $2)) }
  ;

chunk:
  | statlistopt laststatopt
  { let open Core.Std in
    let stats = $1 @ $2 in
    if List.is_empty stats then
      None
    else
      Some (with_range (List.hd_exn stats).loc (List.last_exn stats).loc stats)
  }
  ;

statlistopt:
  | statlist { $1 }
  | (* empty *) { [] }
  ;

laststatopt:
  | laststat { [$1] }
  | laststat SEMI { [$1; nop $2] }
  | (* empty *) { [] }
  ;

statlist:
  | statlist_rev { List.rev $1 }
  ;

statlist_rev:
  | stat { [$1] }
  | statlist_rev stat { $2 :: $1 }
  ;

block:
  | chunk { $1 }
  ;

stat:
  | SEMI { nop $1 }
  | varlist EQ explist
  { with_range $1.loc $3.loc (Assign ($1, $2, $3)) }
  | functioncall %prec app { $1 }
  | DCOLON IDENT DCOLON
  { with_range $1 $3 (Label ($1, $2, $3)) }
  | BREAK { Location.with_loc $1 (Break $1) }
  | GOTO IDENT { with_range $1 $2.loc (Goto ($1, $2)) }
  | DO block END { with_range $1 $3 (Do ($1, $2, $3)) }
  | WHILE exp DO block END
  { with_range $1 $5 (While ($1, $2, $3, $4, $5)) }
  | REPEAT block UNTIL exp
  { with_range $1 $4.loc (Repeat ($1, $2, $3, $4)) }
  | ifstat { $1 }
  | FOR IDENT EQ exp COMMA exp DO block END
  { let desc = Num_for ($1, $2, $3, $4, $5, $6, None, $7, $8, $9) in
    with_range $1 $9 desc }
  | FOR IDENT EQ exp COMMA exp COMMA exp DO block END
  { let desc = Num_for ($1, $2, $3, $4, $5, $6, Some ($7, $8), $9, $10, $11) in
    with_range $1 $11 desc }
  | FOR namelist IN explist DO block END
  { let desc = Gen_for ($1, $2, $3, $4, $5, $6, $7) in
    with_range $1 $7 desc }
  | FUNCTION funcname funcbody
  { with_range $1 $3.loc (Func_def ($1, $2, $3)) }
  | FUNCTION methodname funcbody
  { with_range $1 $3.loc (Method_def ($1, $2, $3)) }
  | LOCAL FUNCTION IDENT funcbody
  { with_range $1 $4.loc (Local_func_def ($1, $2, $3, $4)) }
  | LOCAL namelist
  { with_range $1 $2.loc (Local_var_def ($1, $2, None)) }
  | LOCAL namelist EQ explist
  { with_range $1 $4.loc (Local_var_def ($1, $2, Some ($3, $4))) }
  ;

laststat:
  | RETURN { Location.with_loc $1 (Return ($1, None)) }
  | RETURN explist
  { with_range $1 $2.loc (Return ($1, Some $2)) }
  ;

ifstat:
  | ifblock END { make_if [$1] None $2 }
  | ifblock elseifblocklist END { make_if ($1 :: $2) None $3 }
  | ifblock elseifblocklist elseblock END
    { make_if ($1 :: $2) (Some $3) $4 }
  | ifblock elseblock END { make_if [$1] (Some $2) $3 }
  ;

ifblock:
  | IF exp THEN block
  { with_range $1 (block_loc $4 $3) ($1, $2, $3, $4) }
  ;

elseifblocklist:
  | elseifblocklist_rev { List.rev $1 }
  ;

elseifblocklist_rev:
  | elseifblock { [$1] }
  | elseifblocklist_rev elseifblock { $2 :: $1 }
  ;

elseifblock:
  | ELSEIF exp THEN block
  { with_range $1 (block_loc $4 $3) ($1, $2, $3, $4) }
  ;

elseblock:
  | ELSE block { ($1, $2) }
  ;

funcname:
  | funcname_comps { $1 }
  ;

methodname:
  | funcname_comps COLON IDENT { ($1, $2, $3) }
  ;

funcname_comps:
  | funcname_comps_rev { Utils.delim_seplist_to_loc $1 }
  ;

funcname_comps_rev:
  | IDENT { Seplist.create $1 }
  | funcname_comps_rev DOT IDENT { Seplist.rev_add_pair $1 $2 $3 }
  ;

varlist:
  | varlist_rev { Utils.delim_seplist_to_loc $1 }
  ;

varlist_rev:
  | desc { Seplist.create $1 }
  | varlist_rev COMMA desc { Seplist.rev_add_pair $1 $2 $3 }
  ;

var:
  | desc { Location.with_loc $1.loc (Var $1) }
  ;

desc:
  | IDENT
  { Location.with_loc ($1.loc) (Atom $1) }
  | prefixexp DOT IDENT
  { with_range $1.loc $3.loc (Field_ref ($1, $2, $3)) }
  | prefixexp LBRACK exp RBRACK
  { with_range $1.loc $4 (Subscription ($1, $2, $3, $4)) }
  ;

namelist:
  | namelist_rev { Utils.delim_seplist_to_loc $1 }
  ;

namelist_rev:
  | IDENT { Seplist.create $1 }
  | namelist_rev COMMA IDENT { Seplist.rev_add_pair $1 $2 $3 }
  ;

explist:
  | explist_rev { Utils.delim_seplist_to_loc $1 }
  ;

explist_rev:
  | exp { Seplist.create $1 }
  | explist_rev COMMA exp { Seplist.rev_add_pair $1 $2 $3 }
  ;

exp:
  | NIL { Location.with_loc $1 (Nil $1) }
  | FALSE { Location.with_loc $1 (Bool ($1, false)) }
  | TRUE { Location.with_loc $1 (Bool ($1, true)) }
  | NUMBER { Location.with_loc $1.loc (Number $1) }
  | string { $1 }
  | DOT3 { Location.with_loc $1 (Ellipsis $1) }
  | anonymousfunction { $1 }
  | prefixexp { $1 }
  | tableconstructor { $1 }
  | binexp { $1 }
  | unexp { $1 }
  ;

prefixexp:
  | var %prec app { $1 }
  | functioncall %prec app { $1 }
  | LPAREN exp RPAREN %prec app { make_parenexp $1 $2 $3 }
  ;

functioncall:
  | var args
  { with_range $1.loc $2.loc (Func_call ($1, $2)) }
  | functioncall args
  { with_range $1.loc $2.loc (Func_call ($1, $2)) }
  | LPAREN exp RPAREN args
  { let exp = make_parenexp $1 $2 $3 in
    with_range $1 $4.loc (Func_call (exp, $4)) }
  | prefixexp COLON IDENT args
  { with_range $1.loc $4.loc (Method_call ($1, $2, $3, $4)) }
  ;

args:
  | LPAREN RPAREN
  { with_range $1 $2 (Args ($1, None, $2)) }
  | LPAREN explist RPAREN
  { with_range $1 $3 (Args ($1, Some $2, $3)) }
  | tableconstructor { Location.with_loc $1.loc (Lit_arg $1) }
  | string { Location.with_loc $1.loc (Lit_arg $1) }
  ;

anonymousfunction:
  | FUNCTION funcbody { with_range $1 $2.loc (Func ($1, $2)) }
  ;

funcbody:
  | LPAREN RPAREN block END
    { with_range $1 $4 ($1, None, $2, $3, $4) }
  | LPAREN parlist RPAREN block END
    { with_range $1 $5 ($1, Some $2, $3, $4, $5) }
  ;

parlist:
  | namelist_rev
  { let t = Utils.delim_seplist_to_loc $1 in
    Location.with_loc t.loc (Par_names (t, None)) }
  | namelist_rev COMMA DOT3
  { let t = Utils.delim_seplist_to_loc $1 in
    with_range t.loc $3 (Par_names (t, Some ($2, $3))) }
  | DOT3 { Location.with_loc $1 (Par_vargs $1) }
  ;

tableconstructor:
  | LBRACE RBRACE
  { with_range $1 $2 (Table ($1, None, $2)) }
  | LBRACE fieldlist RBRACE
  { with_range $1 $3 (Table ($1, Some $2, $3)) }
  ;

fieldlist:
  | fieldlistbody_rev
  { Utils.seplist_to_loc
      ~fa:(fun t -> t.Location.loc)
      ~fb:(fun t -> t.Location.loc) @@
      Seplist.of_a_rev @@ Seplist.rev $1
  }
  | fieldlistbody_rev fieldsep
  { let l = Seplist.rev_add $1 $2 in
    Utils.seplist_to_loc
      ~fa:(fun t -> t.Location.loc)
      ~fb:(fun t -> t.Location.loc) @@
      Seplist.of_b_rev @@ Seplist.rev l
  }
  ;
  
fieldlistbody_rev:
  | field { Seplist.create $1 }
  | fieldlistbody_rev fieldsep field { Seplist.rev_add_pair $1 $2 $3 }
  ;

field:
  | LBRACK exp RBRACK EQ exp
  { with_range $1 $5.loc (Expr_assoc ($1, $2, $3, $4, $5)) }
  | IDENT EQ exp
  { with_range $1.loc $3.loc (Key_assoc ($1, $2, $3)) }
  | exp { $1 }
  ;

fieldsep:
  | COMMA { Location.with_loc $1 `Comma }
  | SEMI { Location.with_loc $1 `Semi }
  ;

string:
  | SQUOTED_STRING { Location.with_loc $1.loc (String (Single_quoted, $1)) }
  | DQUOTED_STRING { Location.with_loc $1.loc (String (Double_quoted, $1)) }
  | LONG_STRING { Location.with_loc $1.loc (String (Long, $1)) }

binexp:
  | exp ADD exp { make_binexp $1 Op_add $2 $3 }
  | exp SUB exp { make_binexp $1 Op_sub $2 $3 }
  | exp MUL exp { make_binexp $1 Op_mul $2 $3 }
  | exp DIV exp { make_binexp $1 Op_div $2 $3 }
  | exp POW exp { make_binexp $1 Op_pow $2 $3 }
  | exp REM exp { make_binexp $1 Op_rem $2 $3 }
  | exp DOT2 exp { make_binexp $1 Op_concat $2 $3 }
  | exp LT exp { make_binexp $1 Op_lt $2 $3 }
  | exp LE exp { make_binexp $1 Op_le $2 $3 }
  | exp GT exp { make_binexp $1 Op_gt $2 $3 }
  | exp GE exp { make_binexp $1 Op_ge $2 $3 }
  | exp EQQ exp { make_binexp $1 Op_eq $2 $3 }
  | exp NE exp { make_binexp $1 Op_ne $2 $3 }
  | exp AND exp { make_binexp $1 Op_and $2 $3 }
  | exp OR exp { make_binexp $1 Op_or $2 $3 }
  ;

unexp:
  | SUB exp { make_unexp Op_neg $1 $2 }
  | NOT exp { make_unexp Op_not $1 $2 }
  | NSIGN exp { make_unexp Op_len $1 $2 }
  ;

