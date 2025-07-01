
let g:easycomplete_cmdline_typing = 0

function! easycomplete#cmdline#changed(pfx)
  return
  try
    let item_list = s:normalize(["abc","aaa","aaaasf","asdfsefd","asssfd","aaaas","bsd","aadsfafafaf"])
    let word = s:GetTypingWord()
    call s:console("x", getcmdpos(), strlen(word))
    let start_col = getcmdpos() - strlen(word)
    call easycomplete#pum#complete(0, item_list)
  catch
    echom v:exception
  endtry
endfunction

function! easycomplete#cmdline#enter()
  let g:easycomplete_cmdline_typing = 1
endfunction

function! easycomplete#cmdline#leave()
  let g:easycomplete_cmdline_typing = 0
endfunction

function! easycomplete#cmdline#typing()
  return v:false
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
