:vim version: 7.4 適用済パッチ: 1-133

注意事項等
==========
- 動かない場合は vim で :scriptnames コマンドを実行してプラグインが読み込まれているか確認
- quickfix の仕様 http://vim-jp.org/vimdoc-ja/quickfix.html#quickfix
- syntastic https://github.com/scrooloose/syntastic


ftplugin/lua_luli.vim の使い方
==============================
::

  $ mkdir -p ~/.vim/ftplugin
  $ cp /opt/luli/misc/vim/ftplugin/lua_luli.vim ~/.vim/ftplugin

vim 再起動

::

  $ vim /opt/luli/test/test.lua

filetype が lua の場合に :Luli コマンドが追加されます.

:Luli を実行すると quickfix で luli 実行結果が表示されます.

luli オプションの設定方法
-------------------------
::

  " luli コマンドの指定
  let g:luli_cmd = "/opt/luli/luli"

  " [-I] library load path
  let g:luli_library_load_path = [
   \ "~/Work/lua/libs/",
   \ "/usr/local/lib/lua/"
   \ ]

  " [-cocos] check for cocos2d-x
  let g:luli_cocos_mode = 1

  " [-config] config file
  let g:luli_config_file_path = "~/.luli.ini"

  " [-ignore] skip errors and warnings (e.g. E,W,4)
  let g:luli_ignore_errors = "E"

  " [-l] load (require) the library before the script
  let g:luli_library_files = [
    \ "~/Work/lua/lib/common.lua",
    \ "~/Work/lua/lib/utils.lua",
    \ ]

  " [-limit] set maximum allowed errors and warnings
  let g:luli_limit_errors = 10

  " [-max-line-length] set maximum allowed line length (default: 79)
  let g:luli_max_line_length = 120

  " [-warn-error-all] make all warnings into errors
  let g:luli_warn_error_all = 1

  " [-warn-error] make warnings into errors (e.g. 4,37,123)
  let g:luli_warn_error = 33


syntax_checkers/lua/luli.vim の使い方
=====================================
syntastic というシンタックスチェック全般をよしなにやってくれる vim プラグインに luli のチェッカーを追加する

- NeoBundle をインストール

  - https://gist.github.com/yuitowest/ada2df11ad7d634d0e56#neobundle-%E8%A8%AD%E5%AE%9A
  - 上記 URL の「NeoBundle の設定」のところをやる

- " ここにインストールするプラグインを書きます  のところに追記
  ::

    NeoBundle 'scrooloose/syntastic.git'

- vim 再起動

- :NeoBundleInstall コマンドを実行

- 結果確認
  ::

    $ ls ~/.vim/bundle/
    syntastic

- luli.vim をコピー
  ::

    $ cp /opt/luli/misc/vim/syntax_checkers/lua/luli.vim ~/.vim/bundle/syntastic/syntax_checkers/lua/

- vimrc に設定を追記
  ::

    let g:syntastic_lua_checkers = ['luli']

- vim 再起動

::

  $ vim /opt/luli/test/test.lua

filetype が lua の場合にデフォルトでバッファ保存時に luli が走るようになります

:w で luli の lint 結果が vim に表示されます

エラー詳細を quickfix で見たい場合は :Errors で見れます

luli オプションの設定方法
-------------------------
.vimrc に g:syntastic_lua_luli_args を設定する

例::

  let g:syntastic_lua_luli_args = "-cocos -max-line-length 120"

TODO
-----
- syntax_checkers/lua/luli.vim を vimrc の設定で追加できる方法を探す
