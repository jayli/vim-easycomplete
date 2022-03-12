let s:input_winid = 0
let s:input_buf = 0
let s:tempfile = ""
let s:input_width = 50
let s:input_height = 3
let b:Callbag = v:null
let s:old_text = ""
let s:input_title = "New Name:"
let s:win_borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

function! s:InputCallback(...)
  call s:flush()
endfunction

function! s:ResetBuf(buf)
  let buf = a:buf
  call setbufvar(buf, '&signcolumn', 'no')
  call setbufvar(buf, '&filetype', 'none')
  call setbufvar(buf, '&buftype', "nofile")
  call setbufvar(buf, '&bufhidden', 1)
  call setbufvar(buf, '&modifiable', 1)
  call setbufvar(buf, '&buflisted', 0)
  call setbufvar(buf, '&swapfile', 0)
  call setbufvar(buf, '&undolevels', -1)
  call setbufvar(buf, 'easycomplete_enable', 0)
endfunction


" relative
" line
" col
" width
" height
" title
" highlight
" focusable

function! s:CreateNvimInputWindow(old_text, callback) abort
    let width = s:input_width
    let height = s:input_height
    let opts = {
      \ 'relative':  'editor',
      \ 'row':       winline(),
      \ 'col':       wincol(),
      \ 'width':     width,
      \ 'height':    height,
      \ 'style':     'minimal',
      \ 'focusable': v:false
    \ }

    let title = s:input_title
    let top = "┌─" . title . repeat("─", width - strlen(title) - 3) . "┐"
    let mid = "│" . repeat(" ", width - 2) . "│"
    let bot = "└" . repeat("─", width - 2) . "┘"

    let lines = [top] + repeat([mid], height - 2) + [bot]
    let border_bufnr = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(border_bufnr, 0, -1, v:true, lines)
    let s:border_winid = nvim_open_win(border_bufnr, v:true, opts)
    let opts.row += 1
    let opts.height -= 2
    let opts.col += 2
    let opts.width -= 4
    let opts.focusable = v:true
    let text_bufnr = nvim_create_buf(v:false, v:true)
    call s:ResetBuf(text_bufnr)
    let text_winid = nvim_open_win(text_bufnr, v:true, opts)
    set winhl=Normal:Float
    au WinClosed * ++once :q | call nvim_win_close(s:border_winid, v:true)
    call easycomplete#util#execute(text_winid, [
          \ 'inoremap <expr> <CR> easycomplete#input#PromptHandlerCR()',
          \ 'inoremap <expr> <ESC> easycomplete#input#PromptHandlerESC()',
          \ 'call feedkeys("i","n")'
          \ ])
    return [text_bufnr, text_winid]
endfunction

function! s:CreateVimInputWindow(old_text, callback) abort
  let opt = {
        \ 'filetype':    "txt",
        \ 'col':         'cursor',
        \ 'border':      [1,1,1,1],
        \ 'borderchars': s:win_borderchars,
        \ 'cursorline':  0,
        \ 'maxwidth':    s:input_width,
        \ 'line':        'cursor+1',
        \ 'maxheight':   1,
        \ 'minwidth':    s:input_width,
        \ 'minheight':   1,
        \ 'title':       s:input_title,
        \ 'focusable':   v:true,
        \ 'firstline':   1,
        \ 'fixed':       1,
        \ 'padding':     [0,0,0,0],
        \ }
  let easycomplete_root = easycomplete#util#GetEasyCompleteRootDirectory()
  try
    let buf = term_start("tail -f " . s:CreateBlankFile(), {
            \ 'term_highlight' : 'Pmenu',
            \ 'hidden': 1,
            \ 'term_finish': 'close',
            \ 'exit_cb': function('s:InputCallback')
            \ })
  catch /475/
  endtry

  call s:ResetBuf(buf)
  noa let winid = popup_create(buf, opt)
  call setwinvar(winid, 'autohide', 1)
  call setwinvar(winid, 'float', 1)
  call setwinvar(winid, '&list', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&relativenumber', 0)
  call setwinvar(winid, '&cursorcolumn', 0)
  call setwinvar(winid, '&colorcolumn', 0)
  call setwinvar(winid, '&wrap', 1)
  call setwinvar(winid, '&linebreak', 1)
  call setwinvar(winid, '&conceallevel', 0)
  call easycomplete#util#execute(winid, [
        \ 'tnoremap <expr> <CR> easycomplete#input#PromptHandlerCR()',
        \ 'tnoremap <expr> <ESC> easycomplete#input#PromptHandlerESC()',
        \ ])

  return [buf, winid]
endfunction

function! easycomplete#input#pop(old_text, callbag)
  if has("nvim")
    let input_obj = s:CreateNvimInputWindow(a:old_text, a:callbag)
  else
    let input_obj = s:CreateVimInputWindow(a:old_text, a:callbag)
  endif
  let s:input_winid = input_obj[1]
  let s:input_buf = input_obj[0]
  let b:Callbag = a:callbag
  let s:old_text = a:old_text
endfunction

function! s:CreateBlankFile()
  let tmpfile = tempname()
  silent! call writefile([""], tmpfile, "a")
  let s:tempfile = tmpfile
  return tmpfile
endfunction

function! s:DeleteBlankFile()
  if empty(s:tempfile) | return | endif
  silent! call delete(s:tempfile)
  let s:tempfile = ""
endfunction

function! easycomplete#input#PromptHandlerCR()
  if has("nvim")
    let new_text_line = get(getbufline(s:input_buf, 1, 1), 0, "")
  else
    let new_text_line = term_getline(s:input_buf, '.',)
  endif
  call s:log(new_text_line)
  if empty(new_text_line) || empty(trim(new_text_line))
    call s:log("New text is empty. Nothing will be changed.")
    call s:close()
    return ""
  endif
  let new_text = trim(new_text_line)
  if new_text =~ "\\s"
    call s:log("New text should not contains space character.")
    call s:close()
    return ""
  endif
  let Callbag = b:Callbag
  let old_text = s:old_text
  call s:close()
  call timer_start(60, { -> easycomplete#util#call(Callbag, [old_text, new_text]) })
  return ""
endfunction

function! easycomplete#input#PromptHandlerESC()
  call s:close()
  return ""
endfunction

function! s:close()
  if s:input_winid
    if has('nvim')
      call easycomplete#util#execute(s:input_winid, ["silent noa call feedkeys('\<C-C>ZZ')"])
    else
      call easycomplete#util#execute(s:input_winid, ["silent noa call feedkeys('\<C-C>')"])
    endif
    let s:input_winid = 0
  endif
endfunction

function! s:flush()
  call s:close()
  call s:DeleteBlankFile()
  let s:input_winid = 0
  let s:input_buf = 0
  let s:old_text = ""
  let b:Callbag = v:null
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:get(...)
  return call('easycomplete#util#get', a:000)
endfunction
