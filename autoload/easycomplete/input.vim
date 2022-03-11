let s:input_winid = 0
let s:input_buf = 0
let s:tempfile = ""
let b:Callbag = v:null
let s:old_text = ""
let s:win_borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']

function! s:InputCallback(...)
  call s:flush()
endfunction

function! easycomplete#input#pop(old_text, callbag)
  let title = "Input New Name:"
  let opt = {
        \ 'filetype':    "txt",
        \ 'col':         'cursor',
        \ 'border':      [1,1,1,1],
        \ 'borderchars': s:win_borderchars,
        \ 'cursorline':  0,
        \ 'maxwidth':    50,
        \ 'line':        'cursor+1',
        \ 'maxheight':   1,
        \ 'minwidth':    50,
        \ 'minheight':   1,
        \ 'title':       title,
        \ 'focusable':   v:true,
        \ 'firstline':   1,
        \ 'fixed':       1,
        \ 'padding':     [0,0,0,0],
        \ }
  let easycomplete_root = easycomplete#util#GetEasyCompleteRootDirectory()

  try
    if has("nvim")
      let buf = termopen("tail -f " . s:CreateBlankFile(), {
              \ 'term_highlight' : 'Pmenu',
              \ 'hidden': 1,
              \ 'term_finish': 'close',
              \ 'exit_cb': function('s:InputCallback')
              \ })
    else
      let buf = term_start("tail -f " . s:CreateBlankFile(), {
              \ 'term_highlight' : 'Pmenu',
              \ 'hidden': 1,
              \ 'term_finish': 'close',
              \ 'exit_cb': function('s:InputCallback')
              \ })
    endif
  catch /475/
  endtry

  " noa let buf = bufadd('')
  " noa call bufload(buf)
  noa call setbufvar(buf, '&filetype', "none")
  noa call setbufvar(buf, '&buftype', "nofile")
  noa call setbufvar(buf, '&modifiable', 1)
  noa call setbufvar(buf, '&buflisted', 0)
      call setbufvar(buf, '&swapfile', 0)
      call setbufvar(buf, '&undolevels', -1)
  " noa silent call deletebufline(buf, 1, '$')

  if has("nvim")
    unlet opt.line
    unlet opt.borderchars
    unlet opt.minheight
    unlet opt.cursorline
    unlet opt.filetype
    unlet opt.minwidth
    unlet opt.fixed
    unlet opt.maxwidth
    unlet opt.maxheight
    unlet opt.firstline
    unlet opt.padding
    unlet opt.title
    let opt['col'] = str2nr(col("."))
    let opt.row = winline() + 1
    let opt = {
        \ 'relative': 'cursor',
        \ 'row': 1,
        \ 'col': 3,
        \ 'width': 59,
        \ 'height': 1,
        \ 'style': 'minimal',
        \ 'border': [1,1,1,1],
        \ 'prompt': 1,
        \ }
    let opt = s:convert_config_nvim(opt)
    let winid = nvim_open_win(buf, 0, opt)
    call nvim_win_set_var(winid, 'syntax', 'on')
    call nvim_win_set_option(winid, 'number', v:false)
    call nvim_win_set_option(winid, 'relativenumber', v:false)
    call nvim_win_set_option(winid, 'cursorline', v:false)
    call nvim_win_set_option(winid, 'cursorcolumn', v:false)
    call nvim_win_set_option(winid, 'colorcolumn', '')
    if has('nvim-0.5.0')
      call setwinvar(winid, '&scrolloff', 0)
    endif

  else
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
  endif
  call easycomplete#util#execute(winid, [
        \ 'tnoremap <expr> <CR> easycomplete#input#PromptHandlerCR()',
        \ 'tnoremap <expr> <ESC> easycomplete#input#PromptHandlerESC()',
        \ '',
        \ ''
        \ ])
  let s:input_winid = winid
  let s:input_buf = buf
  let b:Callbag = a:callbag
  let s:old_text = a:old_text
endfunction

function! s:empty_border(border) abort
  if empty(a:border)
    return 1
  endif
  if a:border[0] == 0 && a:border[1] == 0 && a:border[2] == 0 && a:border[3] == 0
    return 1
  endif
  return 0
endfunction

function! s:convert_config_nvim(config) abort
  let valids = ['relative', 'win', 'anchor', 'width', 'height', 'bufpos', 'col', 'row', 'focusable', 'style']
  let result = {}
  for i in valids
    if has_key(a:config, i)
      let result[i] = get(a:config, i, "")
    endif
  endfor
  let border = get(a:config, 'border', [])
  if !s:empty_border(border)
    if result['relative'] ==# 'cursor' && result['row'] < 0
      " move top when has bottom border
      if get(border, 2, 0)
        let result['row'] = result['row'] - 1
      endif
    else
      " move down when has top border
      if get(border, 0, 0) && !get(a:config, 'prompt', 0)
        let result['row'] = result['row'] + 1
      endif
    endif
    " move right when has left border
    if get(border, 3, 0)
      let result['col'] = result['col'] + 1
    endif
    let result['width'] = float2nr(result['width'] + 1 - get(border,3, 0))
  else
    let result['width'] = float2nr(result['width'] + 1)
  endif
  let result['height'] = float2nr(result['height'])
  return result
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
  let new_text_line = term_getline(s:input_buf, '.',)
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
    call easycomplete#util#execute(s:input_winid, ["silent noa call feedkeys('\<C-C>')"])
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
