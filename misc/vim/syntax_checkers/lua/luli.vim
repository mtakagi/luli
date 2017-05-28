if exists("g:loaded_syntastic_lua_luli_checker")
  finish
endif
let g:loaded_syntastic_lua_luli_checker=1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_lua_luli_GetHighlightRegex(pos)
  let result = ''
  let near = matchstr(a:pos['text'], '\mnear ''\zs[^'']\+\ze''')
  if strlen(near) > 0
    if near ==# '<eof>'
      let p = getpos('$')
      let a:pos['lnum'] = p[1]
      let a:pos['col'] = p[2]
      let result = '\%' . p[2] . 'c'
    else
      let result = '\V' . near
    endif
  endif
  return result
endfunction


function! SyntaxCheckers_lua_luli_GetLocList() dict
  let makeprg = self.makeprgBuild({
        \ 'exe': 'luli',
        \ 'args': '-cocos',
        \ 'filetype': 'lua',
        \ 'subchecker': 'luli' })

  let errorformat =  '%f:%l:%c: %m'  " test.lua:4:1: W999 line too long (83 > 79 chanacters)
  " let errorformat =  'luac: %#%f:%l: %m' " luac: test.lua:44: '<eof>' expected near 'syntax'

  return SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat,
        \ 'defaults': { 'bufnr': bufnr(''), 'type': 'E' } })

endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
      \ 'filetype': 'lua',
      \ 'name': 'luli'})

let &cpo = s:save_cpo
unlet s:save_cpo
