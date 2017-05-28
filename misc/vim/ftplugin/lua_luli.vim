let s:save_cpo = &cpo
set cpo&vim

if exists("b:loaded_luli_ftplugin")
  finish
endif
let b:loaded_luli_ftplugin = 1

if exists("g:luli_cmd")
  let s:luli_cmd = g:luli_cmd
else
  let s:luli_cmd = "luli"
endif

" parse list options
function! s:parse_list_option(option_list, option_str)
  let l:result = ""
  for s in a:option_list
    let l:result = l:result
      \ . " ".a:option_str. " ". s
    unlet s
  endfor

  return l:result
endfunction

" luli option setting
""" [-I] library load path
let s:luli_library_load_path_opt = ""
if exists("g:luli_library_load_path")
  \ && type(g:luli_library_load_path) == type([])
  let s:luli_library_load_path_opt
    \ = s:parse_list_option(g:luli_library_load_path, "-I")
endif

""" [-cocos] check for cocos2d-x
let s:luli_cocos_mode_opt = ""
if exists("g:luli_cocos_mode") && g:luli_cocos_mode == 1
  let s:luli_cocos_mode_opt = " -cocos"
endif

""" [-config] config file
let s:luli_config_file_path_opt = ""
if exists("g:luli_config_file_path")
  let s:luli_config_file_path_opt = " -config ". g:luli_config_file_path
end

""" [-ignore] skip errors and warnings (e.g. E,W,4)
let s:luli_ignore_errors_opt = ""
if exists("g:luli_ignore_errors")
  let s:luli_ignore_errors_opt
  \ = " -ignore ". '"'. g:luli_ignore_errors. '"'
endif

""" [-l] load (require) the library before the script
let s:luli_library_files_opt = ""
if exists("g:luli_library_files")
  \ && type(g:luli_library_files) == type([])
  let s:luli_library_files_opt
    \ = s:parse_list_option(g:luli_library_files, "-l")
endif

""" [-limit] set maximum allowed errors and warnings
let s:luli_limit_errors_opt = ""
if exists("g:luli_limit_errors")
  let s:luli_limit_errors_opt = " -limit ". g:luli_limit_errors
endif

""" [-max-line-length] set maximum allowed line length (default: 79)
let s:luli_max_line_length_opt = ""
if exists("g:luli_max_line_length")
  let s:luli_max_line_length_opt = " -max-line-length ". g:luli_max_line_length
endif

""" [-warn-error-all] make all warnings into errors
let s:luli_warn_error_all_opt = ""
if exists("g:luli_warn_error_all") && g:luli_warn_error_all == 1
  let s:luli_warn_error_all_opt = " -warn-error-all"
endif

""" [-warn-error] make warnings into errors (e.g. 4,37,123)
let s:luli_warn_error_opt = ""
if exists("g:luli_warn_error")
  let s:luli_warn_error_opt = ' -warn-error "'. g:luli_warn_error. '"'
endif

" setting options and execute command
function! s:execute_cmd(format, command)
  let l:old_gfm = &grepformat
  let l:old_gp = &grepprg
  let &grepformat = a:format
  let &grepprg = a:command
  silent! grep! %
  let &grepformat = l:old_gfm
  let &grepprg = l:old_gp
  let l:result = getqflist()

  " delete '... and more XX errors and warnings' line
  if s:luli_limit_errors_opt != ""
    call remove(l:result, -1)
  endif

  return l:result
endfunction

function! s:luli()
  if !executable(s:luli_cmd)
    echoerr "File " . s:luli_cmd . " not found. Please install it."
    return
  endif

  set lazyredraw
  cclose

  let l:cmd = s:luli_cmd
    \ . s:luli_library_load_path_opt
    \ . s:luli_cocos_mode_opt
    \ . s:luli_config_file_path_opt
    \ . s:luli_ignore_errors_opt
    \ . s:luli_library_files_opt
    \ . s:luli_limit_errors_opt
    \ . s:luli_max_line_length_opt
    \ . s:luli_warn_error_all_opt
    \ . s:luli_warn_error_opt
  let qflist = s:execute_cmd("%f:%l:%c: %m", l:cmd)

  if qflist != []
    call setqflist(qflist)
    setlocal wrap
    execute 'belowright copen'
  endif

  set nolazyredraw
  redraw!
endfunction

if !exists(":Luli")
  command Luli :call s:luli()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
