======
使い方
======

.. _Validation:

ソースコードを検査する
======================

``luli`` コマンドの引数に検査するファイル名を指定して実行します。

以下は `Programming in Lua <http://www.lua.org/pil/>`_ に掲載されている `マルコフ連鎖アルゴリズム <http://www.lua.org/pil/10.2.html>`_ のソースコードを検査する例です。

``markov.lua``::

  -- Markov Chain Program in Lua
  
  function allwords ()
    local line = io.read()    -- current line
    local pos = 1             -- current position in the line
    return function ()        -- iterator function
      while line do           -- repeat while there are lines
        local s, e = string.find(line, "%w+", pos)
        if s then      -- found a word?
          pos = e + 1  -- update next position
          return string.sub(line, s, e)   -- return the word
        else
          line = io.read()    -- word not found; try next line
          pos = 1             -- restart from first position
        end
      end
      return nil            -- no more lines: end of traversal
    end
  end
  
  function prefix (w1, w2)
    return w1 .. ' ' .. w2
  end
  
  local statetab
  
  function insert (index, value)
    if not statetab[index] then
      statetab[index] = {n=0}
    end
    table.insert(statetab[index], value)
  end
  
  local N  = 2
  local MAXGEN = 10000
  local NOWORD = "¥n"
  
  -- build table
  statetab = {}
  local w1, w2 = NOWORD, NOWORD
  for w in allwords() do
    insert(prefix(w1, w2), w)
    w1 = w2; w2 = w;
  end
  insert(prefix(w1, w2), NOWORD)
  
  -- generate text
  w1 = NOWORD; w2 = NOWORD   -- reinitialize
  for i=1,MAXGEN do
    local list = statetab[prefix(w1, w2)]
    -- choose a random item from list
    local r = math.random(table.getn(list))
    local nextword = list[r]
    if nextword == NOWORD then return end
    io.write(nextword, " ")
    w1 = w2; w2 = nextword
  end

このファイルを ``luli`` コマンドで検査すると、次の結果が得られます。各行の表示内容は、左からファイル名、行番号、列番号、エラーコード、エラーメッセージを示しています。検査結果にエラー扱いのメッセージ ("E" で始まるエラーコード) が一つでもあると、 ``luli`` コマンドは終了コード 255 で終了します。

::

  $ luli markov.lua
  markov.lua:3:10: E1213 global function definition `allwords'
  markov.lua:3:18: E211 whitespace before `('
  markov.lua:7:5: E112 expected an indented block
  markov.lua:8:7: E112 expected an indented block
  markov.lua:8:38: E1801 double-quoted string not including single quotations
  markov.lua:9:7: E112 expected an indented block
  markov.lua:10:9: E112 expected an indented block
  markov.lua:11:9: E112 expected an indented block
  markov.lua:11:16: E1502 bad argument #2 expected number, got [(number, number) | nil]
  markov.lua:12:7: E112 expected an indented block
  markov.lua:13:9: E112 expected an indented block
  markov.lua:14:9: E112 expected an indented block
  markov.lua:15:7: E112 expected an indented block
  markov.lua:16:5: E112 expected an indented block
  markov.lua:17:5: E112 expected an indented block
  markov.lua:18:3: E112 expected an indented block
  markov.lua:21:10: E1213 global function definition `prefix'
  markov.lua:21:16: E211 whitespace before `('
  markov.lua:27:10: E1213 global function definition `insert'
  markov.lua:27:16: E211 whitespace before `('
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:34:7: E1201 unused variable `N'
  markov.lua:34:10: E221 multiple spaces before `='
  markov.lua:36:16: E1801 double-quoted string not including single quotations
  markov.lua:43:10: E702 multiple statements on one line (semicolon or space)
  markov.lua:43:18: E703 statement ends with a semicolon
  markov.lua:48:12: E702 multiple statements on one line (semicolon or space)
  markov.lua:49:6: E225 missing whitespace around `='
  markov.lua:49:6: E225 missing whitespace around `='
  markov.lua:49:8: E231 missing whitespace after comma
  markov.lua:55:22: E1801 double-quoted string not including single quotations
  markov.lua:56:10: E702 multiple statements on one line (semicolon or space)


特定のエラーコードを無視する
============================

特定のエラーコードを無視する (検査結果に表示させない) には、 ``-ignore`` オプションの引数に無視するエラーコードのリストをコンマで区切って指定します。

例: E112, E225 を無視する::

  $ luli -ignore E112,E225 markov.lua
  markov.lua:3:10: E1213 global function definition `allwords'
  markov.lua:3:18: E211 whitespace before `('
  markov.lua:8:38: E1801 double-quoted string not including single quotations
  markov.lua:11:16: E1502 bad argument #2 expected number, got [(number, number) | nil]
  markov.lua:21:10: E1213 global function definition `prefix'
  markov.lua:21:16: E211 whitespace before `('
  markov.lua:27:10: E1213 global function definition `insert'
  markov.lua:27:16: E211 whitespace before `('
  markov.lua:34:7: E1201 unused variable `N'
  markov.lua:34:10: E221 multiple spaces before `='
  markov.lua:36:16: E1801 double-quoted string not including single quotations
  markov.lua:43:10: E702 multiple statements on one line (semicolon or space)
  markov.lua:43:18: E703 statement ends with a semicolon
  markov.lua:48:12: E702 multiple statements on one line (semicolon or space)
  markov.lua:49:8: E231 missing whitespace after comma
  markov.lua:55:22: E1801 double-quoted string not including single quotations
  markov.lua:56:10: E702 multiple statements on one line (semicolon or space)

また、エラーコードのリストに "E" を含めると、 "E" で始まるエラーコードをすべて無視します。現在のバージョンでは "E" 以外の文字で始まるエラーコードを実装していないため、実質的にすべてのエラーが無視されます。

例: すべてのエラーを無視する::

  $ luli -ignore E markov.lua
  (何も表示されません)


特定のエラーコードのみを表示する
================================

特定のエラーコードのみを検査結果に表示するには、 ``-select`` オプションの引数に表示するエラーコードのリストをコンマで区切って指定します。

例: E112, E225 のみを表示する::

  $ luli -select E112,E225 markov.lua
  markov.lua:7:5: E112 expected an indented block
  markov.lua:8:7: E112 expected an indented block
  markov.lua:9:7: E112 expected an indented block
  markov.lua:10:9: E112 expected an indented block
  markov.lua:11:9: E112 expected an indented block
  markov.lua:12:7: E112 expected an indented block
  markov.lua:13:9: E112 expected an indented block
  markov.lua:14:9: E112 expected an indented block
  markov.lua:15:7: E112 expected an indented block
  markov.lua:16:5: E112 expected an indented block
  markov.lua:17:5: E112 expected an indented block
  markov.lua:18:3: E112 expected an indented block
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:49:6: E225 missing whitespace around `='
  markov.lua:49:6: E225 missing whitespace around `='

また ``-ignore`` オプションと同様に、エラーコードのリストに "E" を含めると、 "E" で始まるエラーコードをすべて表示します。現在のバージョンでは "E" 以外の文字で始まるエラーコードを実装していないため、実質的にすべてのエラーが表示されます (``-select`` オプションを指定しない場合と同じ結果になります) 。

例: すべてのエラーのみを表示する::

  $ luli -select E markov.lua
  markov.lua:3:10: E1213 global function definition `allwords'
  markov.lua:3:18: E211 whitespace before `('
  markov.lua:7:5: E112 expected an indented block
  markov.lua:8:7: E112 expected an indented block
  markov.lua:8:38: E1801 double-quoted string not including single quotations
  markov.lua:9:7: E112 expected an indented block
  markov.lua:10:9: E112 expected an indented block
  markov.lua:11:9: E112 expected an indented block
  markov.lua:11:16: E1502 bad argument #2 expected number, got [(number, number) | nil]
  markov.lua:12:7: E112 expected an indented block
  markov.lua:13:9: E112 expected an indented block
  markov.lua:14:9: E112 expected an indented block
  markov.lua:15:7: E112 expected an indented block
  markov.lua:16:5: E112 expected an indented block
  markov.lua:17:5: E112 expected an indented block
  markov.lua:18:3: E112 expected an indented block
  markov.lua:21:10: E1213 global function definition `prefix'
  markov.lua:21:16: E211 whitespace before `('
  markov.lua:27:10: E1213 global function definition `insert'
  markov.lua:27:16: E211 whitespace before `('
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:29:25: E225 missing whitespace around `='
  markov.lua:34:7: E1201 unused variable `N'
  markov.lua:34:10: E221 multiple spaces before `='
  markov.lua:36:16: E1801 double-quoted string not including single quotations
  markov.lua:43:10: E702 multiple statements on one line (semicolon or space)
  markov.lua:43:18: E703 statement ends with a semicolon
  markov.lua:48:12: E702 multiple statements on one line (semicolon or space)
  markov.lua:49:6: E225 missing whitespace around `='
  markov.lua:49:6: E225 missing whitespace around `='
  markov.lua:49:8: E231 missing whitespace after comma
  markov.lua:55:22: E1801 double-quoted string not including single quotations
  markov.lua:56:10: E702 multiple statements on one line (semicolon or space)

.. _Noqa:

特定の行に対する検査を抑制する
==============================

特定の行に対する検査を抑制したいときは、その行のインラインコメントに ``luli: noqa`` と記述します。次に例を示します。

``unknown_var.lua``::

  print(unknown_var)

``luli: noqa`` を指定しない場合::

  $ luli unknown_var.lua
  unknown_var.lua:1:7: E1202 unassigned variable `unknown_var'

``noqa.lua``::

  print(unknown_var)  -- luli: noqa

``luli: noqa`` を指定した場合::

  $ luli noqa.lua
  (何も表示されません)


行の長さを指定する
===================

一行の文字数が規定の値を超えると E501 が指摘されます。この値は ``-max-line-length`` オプションで設定できます。デフォルトは 79 文字です。

文字数は UTF-8 の文字を一文字としてカウントされます。


未使用のローカル変数に対する検査を局所的に抑制する
==================================================

ローカル変数 (関数定義の仮引数を含みます) がどこからも参照されていないと E1201 が指摘されます。特定のローカル変数に対してこの検査を抑制したい場合は :ref:`その行ごと検査を抑制 <Noqa>` してもよいですが、この方法では E1201 以外のエラーも抑制されます。 ``-anon-args`` オプションを使うと、名前がアンダースコアで始まるローカル変数に対して E1201 の検査のみを抑制できます。

次に例を示します。

::

  -- _c に対して E1201 は指摘されません
  local function f(a, b, _c)
    print(a + b)
  end

  f(1, 2)

なお、 ``for`` 文の制御変数に限り E1201 の検査は行われません。 ``-anon-args`` オプションの指定時でも、制御変数の名前をアンダースコアで始める必要はありません。

::

  -- ループ内で i を使わなくても E1201 は指摘されません
  for i in ipairs(t) do
    ...
  end


.. _SpellCheck:

変数名のスペルチェックを行う
============================

``luli`` は変数名の簡易的なスペルチェックを行います。参照以前に一度も値が代入されていない変数がある場合、その時点で名前の似ている変数が宣言されていれば、最も似ている名前をエラーメッセージに含めます。

次に例を示します。

``my_var.lua``::

  local my_var
  print(my_val)  -- my_var の間違い

実行::

  $ luli my_var.lua
  ../a.lua:1:7: E1201 unused variable `my_var'
  ../a.lua:2:7: E1202 unassigned variable `my_val' (did you mean `my_var'?)

スペルチェックを無効にするには ``-no-spell-check`` オプションを指定します。解析するソースコードの量が多いとスペルチェックに時間がかかる可能性があるため、 ``luli`` コマンドの実行が遅いと感じた場合はスペルチェックを無効にしてみてください。


.. _LoadingModules:

モジュールをロードする
======================

検査対象のソースコードに関連するモジュールをロードすることで、より精度の高い検査を行えます。
 
- 他のモジュールで定義されているグローバル変数・グローバル関数を識別できるようになります。未代入の変数に関するエラーの指摘が減る他、スペルチェックの精度も向上します。

- モジュールの循環参照を検出できます。

文法エラーを除き、ロードしたモジュールに関するエラーは出力されません。


ソースコード中で使われているモジュールをロードする
--------------------------------------------------

デフォルトの設定では、トップレベルのチャンクに ``require`` 関数呼び出し式があると、その実引数 (文字列リテラル) をモジュールとしてロードします。例えば ``require 'foo'`` を含むコードに対して luli を実行すると、ロードパスから ``foo`` モジュール (``foo.lua``) を探してロードします。

この動作を無効にするには、 ``-no-autoload`` オプションを指定します。


モジュールを指定してロードする
------------------------------

``-l`` オプションの引数にモジュール名を指定すると、そのモジュールをソースコードの検査前にロードします。


ロードパスを追加する
--------------------

ロードパスを追加するには、 ``-L`` オプションで追加するディレクトリを指定します。
luli を実行したときのディレクトリは自動的にロードパスに追加されます。
