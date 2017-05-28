type op =
  | Unary_op of unop
  | Bin_op of binop

and unop = unop_desc Location.loc

and unop_desc =
  | Op_neg               (* "-" *)
  | Op_not               (* "not" *)
  | Op_len               (* "#" *)

and binop = binop_desc Location.loc

and binop_desc =
  | Op_eq                (* "==" *)
  | Op_ne                (* "~=" *)
  | Op_le                (* "<=" *)
  | Op_lt                (* "<" *)
  | Op_ge                (* ">=" *)
  | Op_gt                (* ">" *)
  | Op_add               (* "+" *)
  | Op_sub               (* "-" *)
  | Op_mul               (* "*" *)
  | Op_div               (* "/" *)
  | Op_rem               (* "%" *)
  | Op_pow               (* "^" *)
  | Op_and               (* "and" *)
  | Op_or                (* "or" *)
  | Op_concat            (* ".." *)

type ast = ast_desc Location.loc

and ast_desc =
  | Prog           of chunk * eof
  | Nop            of semi
  | Return         of tok_return * explist option
  | Break          of tok_break
  | Label          of tok_dcolon * word * tok_dcolon
  | Goto           of tok_goto * word
  | Assign         of varlist * eq * explist
  | Func_call      of ast * args
  | Method_call    of ast * colon * word * args
  | Do             of tok_do * chunk * tok_end
  | While          of tok_while * ast * tok_do * chunk * tok_end
  | Repeat         of tok_repeat * chunk * tok_until * ast
  | If             of condbody list * (tok_else * chunk) option * tok_end
  | Num_for        of tok_for * word * eq * ast * comma * ast * (comma * ast) option * tok_do * chunk * tok_end
  | Gen_for        of tok_for * wordlist * tok_in * explist * tok_do * chunk * tok_end
  | Func_def       of tok_function * wordlist * funcbody
  | Method_def     of tok_function * (wordlist * colon * word) * funcbody
  | Local_func_def of tok_local * tok_function * word * funcbody
  | Local_var_def  of tok_local * wordlist * (eq * explist) option
  | Var            of var
  | Nil            of tok_nil 
  | Bool           of tok_bool * bool
  | Number         of word
  | String         of quote * word
  | Ellipsis       of ellipsis
  | Func           of tok_function * funcbody
  | Paren_expr     of lparen * ast * rparen
  | Table          of lbrace * fieldlist option * rbrace
  | Key_assoc      of word * eq * ast
  | Expr_assoc     of lbrack * ast * rbrack * eq * ast
  | Bin_expr       of ast * binop * ast
  | Unary_expr     of unop * ast

and chunk = ast list Location.loc option

and args = args_desc Location.loc

and args_desc =
  | Args of lparen * explist option * rparen
  | Lit_arg of ast

and condbody = (tok_if * ast * tok_then * chunk) Location.loc

and fieldlist = (ast, fieldsep) Seplist.t Location.loc

and funcbody = (lparen * parlist option * rparen * chunk * tok_end) Location.loc

and var = var_desc Location.loc

and var_desc =
  | Atom of word
  | Field_ref of ast * dot * word
  | Subscription of ast * lbrack * ast * rbrack

and varlist = (var, comma) Seplist.t Location.loc

and explist = (ast, comma) Seplist.t Location.loc

and word = string Location.loc

and wordlist = (word, comma) Seplist.t Location.loc

and fieldsep = [`Comma | `Semi] Location.loc

and parlist = parlist_desc Location.loc

and parlist_desc =
  | Par_names of wordlist * (comma * ellipsis) option
  | Par_vargs of ellipsis

and quote =
  | Single_quoted
  | Double_quoted
  | Long

and eof = Location.t
and lparen = Location.t
and rparen = Location.t
and lbrack = Location.t
and rbrack = Location.t
and lbrace = Location.t
and rbrace = Location.t
and eq = Location.t
and comma = Location.t
and ellipsis = Location.t
and colon = Location.t
and semi = Location.t
and dot = Location.t
and tok_for = Location.t
and tok_in = Location.t
and tok_do = Location.t
and tok_end = Location.t
and tok_if = Location.t
and tok_then = Location.t
and tok_else = Location.t
and tok_while = Location.t
and tok_repeat = Location.t
and tok_until = Location.t
and tok_local = Location.t
and tok_function = Location.t
and tok_return = Location.t
and tok_break = Location.t
and tok_dcolon = Location.t
and tok_goto = Location.t
and tok_nil = Location.t
and tok_bool = Location.t

