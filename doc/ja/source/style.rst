.. _CodingStyle:

====================
コーディングスタイル
====================

.. contents:: 目次

以下に luli が検査するコーディングスタイルを示します。現時点で Lua には公式に推奨されるコーディングスタイルがないため、次のコーディングスタイルガイドを参考にして作成しました。

- `Lua: Technical Note 7 <http://www.lua.org/notes/ltn007.html>`_
- `lua-users wiki: Lua Style Guide <http://lua-users.org/wiki/LuaStyleGuide>`_
- `Olivine Labs: Lua Style Guide <https://github.com/Olivine-Labs/lua-style-guide/blob/master/README.md>`_
- `PEP 8 -- Style Guide for Python Code <http://legacy.python.org/dev/peps/pep-0008/>`_
- `Google Python Style Guide <http://google-styleguide.googlecode.com/svn/trunk/pyguide.html>`_
- `The Unofficial Ruby Usage Guide <http://www.caliban.org/ruby/rubyguide.shtml>`_
- `Google JavaScript Style Guide <https://google-styleguide.googlecode.com/svn/trunk/javascriptguide.xml>`_

以下の記述で「未実装」と付記されている項目は、現在 luli では検査できません。


レイアウト
==========

改行
------

- 複数の文から構成される文では、次の位置で改行します (以下、これらの行を論理行と呼びます) 。

  - ``end`` の後
  - ``then`` の後 (``if`` 文、 ``elseif`` 文)
  - ``do`` の後 (``for`` 文、``do`` 文、 ``while`` 文)
  - ``repeat`` の後 (``repeat`` 文)
  - 関数定義の仮引数の後 (``function`` 文、 ``local function`` 文)

- 括弧 (波括弧、角括弧、丸括弧) の内側では、次の箇所で改行をしてもよいです (以下、括弧の内側で改行する行を継続行と呼びます) 。

  - 開き括弧の後
  - 閉じ括弧の前
  - コンマの後

  ::

    -- 改行しない
    my_func(a, b, c)

    -- 各要素で改行する
    my_func(
      a,
      b,
      c
    )

    -- 開き括弧の後に改行しない
    my_func(a,
            b,
            c
            )

    -- 閉じ括弧の前で改行しない
    my_func(
      a,
      b,
      c)


インデント
----------

角括弧内の継続行の検査は未実装です。

- インデント 1 つにつき、 2 つのスペースを使います。タブは使うべきではありません。

- 継続行のインデントは二種類あります。一つはインデントの位置を開始行の開き括弧に揃えるビジュアルインデント、もう一つは開始行に対してインデントレベルを深める吊り下げインデントです。開き括弧の後で改行しなければビジュアルインデント、改行すれば吊り下げインデントとみなします。

  - ビジュアルインデントの継続行では、インデントを開き括弧に揃えます。

    ::

      my_list = {1, 2, 3,
                 4, 5, 6}
      foo = long_function_name(var_one, var_two,
                               var_three, var_four)

  - 吊り下げインデントの継続行では、継続行の終了後にチャンクが続かないのであれば、 1 レベル深いインデントを行います。

    ::

      long_function_name(
        var_one, var_two, var_three,
        var_four)

  - チャンクが続く場合、継続行とチャンクのインデントを区別するために 2 レベル以上深いインデントを行います。

    ::

      local function long_function_name(
          var_one, var_two, var_three,
          var_four)
        print(var_one)
      end

- 継続行の閉じ括弧の前で改行する場合、閉じ括弧の位置はインデントの種別によって異なります。

  - ビジュアルインデントでは、閉じ括弧の位置を継続行に揃えます。

    ::

      my_list = {1, 2, 3,
                 4, 5, 6,
                 }
      result = some_function_that_takes_arguments('a', 'b', 'c',
                                                  'd', 'e', 'f',
                                                  )

  - 吊り下げインデントでは、閉じ括弧の位置を開始行に揃えます。

    ::

      my_list = {
        1, 2, 3,
        4, 5, 6,
      }
      result = some_function_that_takes_arguments(
        'a', 'b', 'c',
        'd', 'e', 'f',
      )

- 匿名関数のインデントは ``function`` の位置を基準とし、チャンクの位置は論理行の規則に従います。 ``end`` の位置は ``function`` の開始位置に揃えます。

  ::

    -- 代入
    f = function (a, b, c)
          return a + b + c
        end

    -- 吊り下げインデント
    foo = my_func(
      var_one,
      function (arg)
        return arg
      end)

    -- ビジュアルインデント
    foo = my_func(var_one,
                  function (arg)
                    return arg
                  end)

    -- 一行に複数の引数を羅列する場合
    foo = my_func(var_one, function (arg)
                             return arg
                           end)

    -- テーブルコンストラクタで匿名関数を代入する (吊り下げインデント)
    foo = my_func(
      {
        my_func = function (arg)
                    return arg
                  end
      })

    -- テーブルコンストラクタで匿名関数を代入する (ビジュアルインデント)
    foo = my_func({
                    my_func = function (arg)
                                return arg
                              end
                  })


行の長さ
--------

一行を 79 文字以内に収めます。この値は ``-max-line-length`` オプションで変更できます。

マルチバイト文字は 1 文字として計算されます。現在対応している文字エンコーディングは UTF-8 のみです。


空行
----

- 関数定義間を 2 つの空行で区切ります (未実装) 。

- ファイルの最後に空行を入れるべきではありません。


式や文の中のスペース
====================

- 括弧 (丸括弧、角括弧、波括弧) の内側にスペースを入れるべきではありません。

  推奨:

  ::

    foo()
    foo(a, b)
    bar[i] = x
    baz = {}

  非推奨:

  ::

    foo( )
    foo( a, b )
    bar[ i ] = x
    baz = { }

- コンマ、セミコロンの前にスペースを入れるべきではありません。

  推奨:

  ::

    { a = 1, b = 2 }
    foo(a, b)
    return a, b
    foo(); bar(); baz()

  非推奨:

  ::

    { a = 1 , b = 2 }
    foo(a , b)
    return a , b
    foo() ; bar() ; baz()

- ピリオド、コロンの前後にスペースを入れるべきではありません。

  推奨:

  ::

    foo.bar = baz
    self:foo(a, b)

  非推奨:

  ::

    foo . bar = baz
    self : foo(a, b)

- 関数呼び出し式の実引数を囲む開き丸括弧の前にスペースを入れるべきではありません。

  推奨:

  ::

    foo(a, b)

  非推奨:

  ::

    foo (a, b)

- 関数呼び出し式がリテラル値 (文字列またはテーブルコンストラクタ) を唯一の引数とし、丸括弧を省略する場合、リテラル引数の前に 1 つのスペースを入れます。

  推奨:

  ::

    require "foo"
    print "hello"
    foo { key = value }

  非推奨:

  ::

    require"foo"
    print"hello"
    foo{ key = value }

- テーブルアクセス式の開き角括弧の前にスペースを入れるべきではありません。

  推奨:

  ::

    v = t[1]
    t[1] = v

  非推奨:

  ::

    v = t [1]
    t [1] = v

- 予約語の後には 1 つのスペースのみを入れます。

  推奨:

  ::

    function foo(a, b)
      return a + b
    end
    local bar

  非推奨:

  ::

    function   foo(a, b)
      return    a + b
    end
    local   bar

- 二項演算子の前後に 1 つのスペースを入れます。

- 長さ演算子 (``#``) と式の間にスペースを入れるべきではありません。

  推奨:

  ::

    len = #foo

  非推奨:

  ::

    len = # foo

- (Lua 5.2) ラベル名の前後にスペースを入れるべきではありません。

  推奨:

  ::

    ::mylabel::

  非推奨:

  ::

    :: mylabel ::

- 行末に不要なスペースを入れるべきではありません。


文
======

- チャンクを含む構文を除き、一行に 1 つの文を記述します。セミコロンで区切って複数の文を記述すべきではありません。

  推奨:

  ::

    if ok then
      print "hello"
    end

    foo()
    bar()
    baz()

  非推奨:

  ::

    if ok then print "hello" end

     foo(); bar(); baz()

- 匿名関数のみ、チャンクが 1 つの文からなるのであれば一行で記述してもよいです。

  推奨:

  ::

    f = function ()
          return v
        end

    f = function (v) return v end

  非推奨:

  ::

    f = function (v) print(v) return v end
    f = function (v) print(v); return v end

- 関数の最後に意味のない文を記述すべきではありません。
  
  - ラベル文
  - ``break`` 文
  - 値を省略した ``return`` 文

  非推奨:

  ::

    local function foo()
      ...
      -- 不要な return
      return
    end


コメント
========

ブロックコメント
----------------

- 論理行と同様の規則でインデントします。

- ``--`` の後にスペース以外の文字が続く場合は、 1 つ以上のスペースを入れます。コメントが ``-`` のみで構成されるのであれば、スペースは不要です。

  推奨:

  ::

    --------------------
    -- コメント
    --   コメント
    --
    --------------------

  非推奨:

  ::

    --++++++++++++++--
    --コメント



インラインコメント
------------------

- ``--`` の前に 2 つ以上のスペースを、後ろに 1 つ以上のスペースを入れます。

  推奨:

  ::

    local x = 1  -- コメント

  非推奨:

  ::

    local x = 1 -- コメント
    local x = 1  --コメント


文字列
======

- 文字列リテラルはシングルクオートで囲みます。ただし、文字列がシングルクオートを含むのであればダブルクオートで囲んでもよいです。
      
  推奨:

  ::

    s = 'foobarbaz'
    s = "'foo' 'bar' 'baz'"


- オブジェクトを文字列に変換するために空文字列の結合を利用すべきではありません。 ``tostring()`` を使うべきです。

  推奨:

  ::

    data = tostring(obj)

  非推奨:

  ::

    data = '' .. obj


関数
====

- ローカル変数の初期値に匿名関数定義式を代入すべきではありません。ローカル関数として定義すべきです。

  推奨:

  ::

    local function foo()
      ..
    end

  非推奨:

  ::

    local foo = function ()
                  ..
                end


命名規則
========

- 次の識別子は「アルファベット小文字 + アンダースコア (snake case) 」で構成すべきです。

  - 変数 (ローカル変数、グローバル変数)
  - 関数
  - メソッド
  - テーブルのフィールド

- 擬似的なクラスベースのオブジェクト指向プログラミングを行う場合、クラス名は「単語の先頭を大文字とする複合語 (camel case) 」で構成すべきです (未実装) 。

- 再代入させたくない変数の名前は「アルファベット大文字 + アンダースコア」で構成すべきです (未実装) 。

  推奨:

  ::

    MAGIC_NUMBER = 1234

- 識別子にアンダースコアで始まる名前をつけるべきではありません。アンダースコア 1 つ ("``_``") で始まる識別子は組み込み API で、アンダースコア 2 つ ("``__``") で始まる識別子はメタテーブルのフィールドで使われる可能性があります (未実装) 。

- モジュールのファイル名は「アルファベット小文字」で構成される単語または複合語にすべきです。どうしても単語を区切りたい場合はアンダースコアを使います (未実装) 。

- モジュールをロードした戻り値を代入する変数名は、モジュールと同名か「アルファベット小文字 + アンダースコア」で構成すべきです。

  推奨:

  ::

    local mymodule = require "mymodule"

  非推奨:

  ::

    local MyModule = require "mymodule"
