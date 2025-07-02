
let g:easycomplete_cmdline_typing = 0

function! easycomplete#cmdline#changed(char)
  try
    let item_list = s:normalize(["abc","aaa","aaaasf","asdfsefd","asssfd","aaaas","bsd","aadsfafafaf"])
    let word = s:GetTypingWord()
    let pleft = win_screenpos(win_getid())[1]  - 1
    let start_col = getcmdpos() - strlen(word)
  catch
    echom v:exception
  endtry
  " call easycomplete#util#timer_start("easycomplete#cmdline#LazyComplete", [], 10)
endfunction

function! easycomplete#cmdline#LazyComplete()
endfunction

function! easycomplete#cmdline#enter()
  return
endfunction

function! easycomplete#cmdline#leave()
  return
endfunction

function! easycomplete#cmdline#typing()
  if !exists("g:easycomplete_cmdline_typing")
    let g:easycomplete_cmdline_typing = 0
  endif
  return g:easycomplete_cmdline_typing
endfunction

function! s:GetTypingWord()
  let line = getcmdline()
  let pos = getcmdpos() - 1

  if pos < 0
    return ''
  endif

  let start_pos = pos
  while start_pos > 0 && line[start_pos - 1] =~ '\k'
    let start_pos -= 1
  endwhile

  return line[start_pos:pos+1]
endfunction

function! s:normalize(list)
  let new_list = []
  for item in a:list
    call add(new_list, {
          \ "word":item,
          \ "abbr":item,
          \ "kind":'c',
          \ "menu":"p"
          \ })
  endfor
  return new_list
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
