
================
エラーコード
================

- `コーディングスタイル`_

  - `E101: indentation contains mixed spaces and tabs`_
  - `E111: indentation is not a multiple of two spaces`_
  - `E112: expected an indented block`_
  - `E113: unexpected indentation`_
  - `E121: continuation line indentation is not a multiple of two spaces`_
  - `E122: continuation line missing indentation or outdented`_
  - `E123: closing bracket does not match indentation of opening bracket's line`_
  - `E124: closing bracket does not match visual indentation`_
  - `E125: continuation line does not distinguish itself from next logical line`_
  - `E126: continuation line over-indented for hanging indent`_
  - `E127: continuation line over-indented for visual indent`_
  - `E128: continuation line under-indented for visual indent`_
  - `E201: whitespace after \`$1'`_
  - `E202: whitespace before \`$1'`_
  - `E203: whitespace before \`$1'`_
  - `E204: whitespace after \`$1'`_
  - `E211: whitespace before \`('`_
  - `E221: multiple spaces before \`$1'`_
  - `E222: multiple spaces after \`$1'`_
  - `E225: missing whitespace around \`$1'`_
  - `E231: missing whitespace after comma`_
  - `E232: missing whitespace before \`('`_
  - `E233: multiple spaces before \`('`_
  - `E241: multiple spaces after comma`_
  - `E261: at least two spaces before inline comment`_
  - `E262: inline comment should start with \`-- '`_
  - `E265: block comment should start with \`-- '`_
  - `E281: missing whitespace before literal argument`_
  - `E291: trailing whitespace`_
  - `E501: line too long ($1 > $2 characters)`_
  - `E701: multiple statements on one line (keyword)`_
  - `E702: multiple statements on one line (semicolon or space)`_
  - `E703: statement ends with a semicolon`_
  - `E901: $1`_
  - `E911: module \`$1' not found`_
  - `E912: syntax error in module \`$1'`_
  - `E913: cyclic loading module \`$1'`_

- `ソースコードの解析`_

  - `E1101: $1`_
  - `E1201: unused variable \`$1'`_
  - `E1202: unassigned variable \`$1'`_
  - `E1202: unassigned variable \`$1' (did you mean \`$2'?)`_
  - `E1211: local variable \`$1' hides outer local variable (defined at line $2)`_
  - `E1211: local variable \`$1' hides global variable (defined at file \`$2', line $3)`_
  - `E1211: local variable \`$1' hides embedded variable`_
  - `E1212: redefinition local variable of \`$1'`_
  - `E1213: global variable definition \`$1'`_
  - `E1213: global function definition \`$1'`_
  - `E1221: assign initial value to anonymous function`_
  - `E1222: assign \`$1' to anonymous function`_
  - `E1223: already initialized as global variable \`$1'`_
  - `E1301: identifier \`$1' is not in snake case`_
  - `E1511: use \`tostring()' to cast without concatenation`_
  - `E1512: use of element 0 for array-like table access`_
  - `E1601: block may never be used`_
  - `E1602: meaningless condition (block shall be run)`_
  - `E1801: double-quoted string not including single quotations`_
  - `E1802: redundant parenthesis`_

- `未実装`_

  - `E133: closing bracket is missing indentation`_
  - `E223:  tab before \`$1'`_
  - `E224:  tab after \`$1'`_
  - `E226: missing whitespace around \`$1'`_
  - `E227: missing whitespace around \`$1'`_
  - `E228: missing whitespace around \`%%'`_
  - `E242: tab after comma`_
  - `E271: multiple spaces after keyword`_
  - `E272: multiple spaces before keyword`_
  - `E273: tab after keyword`_
  - `E274: tab before keyword`_
  - `W292: no newline at end of file`_
  - `W293: blank line contains whitespace`_
  - `W301: expected 1 blank line, found 0`_
  - `W302: expected 2 blank lines, found 0`_
  - `W303: too many blank lines (3)`_
  - `W391: blank line at end of file`_
  - `E1231: unassigned field \`$1' (did you mean \`$2'?)`_
  - `E1302: identifier \`$1' is not in camel case`_
  - `E1501: expected $1 arguments, got $2`_
  - `E1502: bad argument #$1 expected $2, got $3`_

コーディングスタイル
====================

E101: indentation contains mixed spaces and tabs
----------------------------------------------------

:エラーコード: E101
:エラーレベル: エラー

インデントにスペースとタブが混在している

E111: indentation is not a multiple of two spaces
-----------------------------------------------------

:エラーコード: E111
:エラーレベル: エラー

インデントサイズが 2 の倍数ではない

E112: expected an indented block
------------------------------------

:エラーコード: E112
:エラーレベル: エラー

インデントブロックがない

E113: unexpected indentation
--------------------------------

:エラーコード: E113
:エラーレベル: エラー

予期しないインデント

E121: continuation line indentation is not a multiple of two spaces
-----------------------------------------------------------------------

:エラーコード: E121
:エラーレベル: エラー

継続行のインデントサイズが 2 の倍数ではない

E122: continuation line missing indentation or outdented
------------------------------------------------------------

:エラーコード: E122
:エラーレベル: エラー

継続行のインデントが存在しない、またはインデントが戻されている

E123: closing bracket does not match indentation of opening bracket's line
------------------------------------------------------------------------------

:エラーコード: E123
:エラーレベル: エラー

吊り下げインデント時、閉じ括弧の行のインデントが開き括弧の行と揃っていない

E124: closing bracket does not match visual indentation
-----------------------------------------------------------

:エラーコード: E124
:エラーレベル: エラー

ビジュアルインデント時、閉じ括弧の位置が開き括弧と揃っていない

E125: continuation line does not distinguish itself from next logical line
------------------------------------------------------------------------------

:エラーコード: E125
:エラーレベル: エラー

継続行のインデントと論理行のインデントの区別がない

E126: continuation line over-indented for hanging indent
------------------------------------------------------------

:エラーコード: E126
:エラーレベル: エラー

吊り下げインデント時、継続行のインデントが多い

E127: continuation line over-indented for visual indent
-----------------------------------------------------------

:エラーコード: E127
:エラーレベル: エラー

ビジュアルインデント時、継続行のインデントが多い

E128: continuation line under-indented for visual indent
------------------------------------------------------------

:エラーコード: E128
:エラーレベル: エラー

ビジュアルインデント時、継続行のインデントが少ない

E201: whitespace after \`$1'
-------------------------------

:エラーコード: E201
:エラーレベル: エラー
:$1: 開き括弧

開き括弧の次にスペースが (1 つ以上) ある

E202: whitespace before \`$1'
--------------------------------

:エラーコード: E202
:エラーレベル: エラー
:$1: 閉じ括弧

閉じ括弧の前にスペースが (1 つ以上) ある

E203: whitespace before \`$1'
--------------------------------

:エラーコード: E203
:エラーレベル: エラー
:$1: 記号

記号の前にスペースが (1 つ以上) ある

E204: whitespace after \`$1'
-------------------------------

:エラーコード: E204
:エラーレベル: エラー
:$1: 記号

記号の後にスペースが (1 つ以上) ある

E211: whitespace before \`('
-------------------------------

:エラーコード: E211
:エラーレベル: エラー

\`(' の前にスペースが (1 つ以上) ある

E221: multiple spaces before \`$1'
-------------------------------------

:エラーコード: E221
:エラーレベル: エラー
:$1: 演算子

演算子の前にスペースが多い (2 つ以上)

E222: multiple spaces after \`$1'
------------------------------------

:エラーコード: E222
:エラーレベル: エラー
:$1: 演算子

演算子の次にスペースが多い (2 つ以上)

E225: missing whitespace around \`$1'
----------------------------------------

:エラーコード: E225
:エラーレベル: エラー
:$1: 演算子

演算子の前後にスペースがない

E231: missing whitespace after comma
----------------------------------------

:エラーコード: E231
:エラーレベル: エラー

\`,' の次にスペースがない

E232: missing whitespace before \`('
---------------------------------------

:エラーコード: E232
:エラーレベル: エラー

\`(' の前にスペースがない

E233: multiple spaces before \`('
------------------------------------

:エラーコード: E233
:エラーレベル: エラー

\`(' の前にスペースが多い (2 つ以上)

E241: multiple spaces after comma
-------------------------------------

:エラーコード: E241
:エラーレベル: エラー

\`,' の次にスペースが多い (2 つ以上)

E261: at least two spaces before inline comment
---------------------------------------------------

:エラーコード: E261
:エラーレベル: エラー

インラインコメントの前に 2 文字分のスペースがない

E262: inline comment should start with \`-- '
------------------------------------------------

:エラーコード: E262
:エラーレベル: エラー

インラインコメントが \`-- ' で始まっていない

E265: block comment should start with \`-- '
-----------------------------------------------

:エラーコード: E265
:エラーレベル: エラー

ブロックコメントが \`-- ' で始まっていない

E281: missing whitespace before literal argument
----------------------------------------------------

:エラーコード: E281
:エラーレベル: エラー

リテラル引数 (文字列またはテーブル) の前にスペースがない

E291: trailing whitespace
-----------------------------

:エラーコード: E291
:エラーレベル: エラー

行末にスペースが含まれている

E501: line too long ($1 > $2 characters)
--------------------------------------------

:エラーコード: E501
:エラーレベル: エラー
:$1: 該当行の文字数
:$2: 規定の文字数

一行の文字数が規定より多い

E701: multiple statements on one line (keyword)
---------------------------------------------------

:エラーコード: E701
:エラーレベル: エラー

一行に複数の文がある (制御構文のキーワード後)

E702: multiple statements on one line (semicolon or space)
--------------------------------------------------------------

:エラーコード: E702
:エラーレベル: エラー

一行に複数の文がある (セミコロンまたはスペース区切り)

E703: statement ends with a semicolon
-----------------------------------------

:エラーコード: E703
:エラーレベル: エラー

文がセミコロンで終わっている

E901: $1
------------

:エラーコード: E901
:エラーレベル: エラー
:$1: エラー内容

文法エラー

E911: module \`$1' not found
-------------------------------

:エラーコード: E911
:エラーレベル: エラー
:$1: モジュール名

モジュールを見つけられなかった

E912: syntax error in module \`$1'
-------------------------------------

:エラーコード: E912
:エラーレベル: エラー
:$1: モジュール名

モジュールに文法エラーがある

E913: cyclic loading module \`$1'
------------------------------------

:エラーコード: E913
:エラーレベル: エラー
:$1: モジュール名

モジュールのロードが循環している

ソースコードの解析
==================

E1101: $1
------------

:エラーコード: E1101
:エラーレベル: エラー
:$1: エラー内容

ディレクティブエラー

E1201: unused variable \`$1'
------------------------------

:エラーコード: E1201
:エラーレベル: エラー
:$1: 変数名

未使用の変数

E1202: unassigned variable \`$1'
----------------------------------

:エラーコード: E1202
:エラーレベル: エラー
:$1: 変数名

未代入の変数

E1202: unassigned variable \`$1' (did you mean \`$2'?)
-------------------------------------------------------

:エラーコード: E1202
:エラーレベル: エラー
:$1: 変数名
:$2: 候補の変数名

未代入の変数 (候補つき)

E1211: local variable \`$1' hides outer local variable (defined at line $2)
-----------------------------------------------------------------------------

:エラーコード: E1211
:エラーレベル: エラー
:$1: 変数名
:$2: 行番号

ローカル変数が外側スコープのローカル変数を隠している

E1211: local variable \`$1' hides global variable (defined at file \`$2', line $3)
-----------------------------------------------------------------------------------

:エラーコード: E1211
:エラーレベル: エラー
:$1: 変数名
:$2: ファイル名
:$3: 行番号

ローカル変数がグローバル変数を隠している

E1211: local variable \`$1' hides embedded variable
-----------------------------------------------------

:エラーコード: E1211
:エラーレベル: エラー
:$1: 変数名

ローカル変数が組み込み変数を隠している

E1212: redefinition local variable of \`$1'
---------------------------------------------

:エラーコード: E1212
:エラーレベル: エラー
:$1: 変数名

同名のローカル変数が同一スコープで定義されている

E1213: global variable definition \`$1'
-----------------------------------------

:エラーコード: E1213
:エラーレベル: エラー
:$1: 変数名

グローバル変数が定義されている

E1213: global function definition \`$1'
-----------------------------------------

:エラーコード: E1213
:エラーレベル: エラー
:$1: 関数名

グローバル関数が定義されている

E1221: assign initial value to anonymous function
----------------------------------------------------

:エラーコード: E1221
:エラーレベル: エラー

ローカル変数の初期値に匿名関数を代入している (多重代入時、右辺の要素数が左辺よりも多い場合)

E1222: assign \`$1' to anonymous function
-------------------------------------------

:エラーコード: E1222
:エラーレベル: エラー
:$1: ローカル変数名

ローカル変数の初期値に匿名関数を代入している

E1223: already initialized as global variable \`$1'
-----------------------------------------------------

:エラーコード: E1223
:エラーレベル: エラー
:$1: 変数名

他のライブラリで初期化済みのグローバル変数に再代入している

E1301: identifier \`$1' is not in snake case
----------------------------------------------

:エラーコード: E1301
:エラーレベル: エラー
:$1: 識別子名

識別子が snake case ではない

E1511: use \`tostring()' to cast without concatenation
--------------------------------------------------------

:エラーコード: E1511
:エラーレベル: エラー

文字列キャストのために結合を利用している (空の文字列を結合している)

E1512: use of element 0 for array-like table access
------------------------------------------------------

:エラーコード: E1512
:エラーレベル: エラー

配列 (テーブル) のインデックス 0 の要素にアクセスしている

E1601: block may never be used
---------------------------------

:エラーコード: E1601
:エラーレベル: エラー

実行されないブロック

E1602: meaningless condition (block shall be run)
----------------------------------------------------

:エラーコード: E1602
:エラーレベル: エラー

意味のない条件式

E1801: double-quoted string not including single quotations
--------------------------------------------------------------

:エラーコード: E1801
:エラーレベル: エラー

シングルクオートを含まないダブルクオートの文字列リテラル

E1802: redundant parenthesis
-------------------------------

:エラーコード: E1802
:エラーレベル: エラー

不要な括弧

未実装
======

E133: closing bracket is missing indentation
------------------------------------------------

:エラーコード: E133
:エラーレベル: エラー

閉じ括弧のインデントが欠けている

E223:  tab before \`$1'
--------------------------

:エラーコード: E223
:エラーレベル: エラー
:$1: 演算子

演算子の前にタブがある

E224:  tab after \`$1'
-------------------------

:エラーコード: E224
:エラーレベル: エラー
:$1: 演算子

演算子の次にタブがある

E226: missing whitespace around \`$1'
----------------------------------------

:エラーコード: E226
:エラーレベル: エラー
:$1: 演算子

算術演算子の前後にスペースがない

E227: missing whitespace around \`$1'
----------------------------------------

:エラーコード: E227
:エラーレベル: エラー
:$1: 演算子

ビット演算子の前後にスペースがない

E228: missing whitespace around \`%%'
----------------------------------------

:エラーコード: E228
:エラーレベル: エラー

モジュロ演算子の前後にスペースがない

E242: tab after comma
-------------------------

:エラーコード: E242
:エラーレベル: エラー

\`,' の次にタブがある

E271: multiple spaces after keyword
---------------------------------------

:エラーコード: E271
:エラーレベル: エラー
:$1: キーワード

キーワードの次にスペースが多い (2 つ以上)

E272: multiple spaces before keyword
----------------------------------------

:エラーコード: E272
:エラーレベル: エラー
:$1: キーワード

キーワードの前にスペースが多い (2 つ以上)

E273: tab after keyword
---------------------------

:エラーコード: E273
:エラーレベル: エラー

キーワードの次にタブがある

E274: tab before keyword
----------------------------

:エラーコード: E274
:エラーレベル: エラー

キーワードの前にタブがある

W292: no newline at end of file
-----------------------------------

:エラーコード: W292
:エラーレベル: 警告

ファイル末尾に改行がない

W293: blank line contains whitespace
----------------------------------------

:エラーコード: W293
:エラーレベル: 警告

空行にスペースが含まれている

W301: expected 1 blank line, found 0
----------------------------------------

:エラーコード: W301
:エラーレベル: 警告

1 行の空行がない

W302: expected 2 blank lines, found 0
-----------------------------------------

:エラーコード: W302
:エラーレベル: 警告

2 行の空行がない

W303: too many blank lines (3)
----------------------------------

:エラーコード: W303
:エラーレベル: 警告

空行が多い (3 行以上)

W391: blank line at end of file
-----------------------------------

:エラーコード: W391
:エラーレベル: 警告

ファイルの終端に空行がある

E1231: unassigned field \`$1' (did you mean \`$2'?)
----------------------------------------------------

:エラーコード: E1231
:エラーレベル: エラー
:$1: フィールド名
:$2: 候補のフィールド名

未代入のフィールド (候補つき)

E1302: identifier \`$1' is not in camel case
----------------------------------------------

:エラーコード: E1302
:エラーレベル: エラー
:$1: 識別子名

識別子が camel case ではない

E1501: expected $1 arguments, got $2
---------------------------------------

:エラーコード: E1501
:エラーレベル: エラー
:$1: 期待される引数の数
:$2: 与えた引数の数

引数の数が異なる

E1502: bad argument #$1 expected $2, got $3
----------------------------------------------

:エラーコード: E1502
:エラーレベル: エラー
:$1: 引数の位置
:$2: 期待される引数の型
:$3: 与えた引数の型

引数の型が異なる
