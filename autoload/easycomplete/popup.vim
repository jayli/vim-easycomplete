" nvim only
" if get(g:, 'easycompelte_popup_mojo_loaded')
"   finish
" endif
" let g:easycompelte_popup_mojo_loaded = 1

let s:max_height = 40
let s:is_vim = !has('nvim')
let s:is_nvim = has('nvim')

augroup easycomplete#popup#au
  autocmd!
  autocmd CompleteDone * call easycomplete#popup#CompleteDone()
  autocmd InsertLeave * call easycomplete#popup#InsertLeave()
  " autocmd VimResized,VimResume * call easycomplete#popup#reopen()
  autocmd VimResized * call easycomplete#popup#reopen()
augroup END

let s:timer = 0
let g:easycomplete_popup_win = 0
let s:event = {}
let s:item = {}
let s:info = []

let s:last_event = {}
let s:last_winargs = []
let s:buf = 0

function! easycomplete#popup#InsertLeave()
  call easycomplete#popup#close()
endfunction

function! easycomplete#popup#MenuPopupChanged(info)
  let s:event = copy(v:event)
  let s:item = copy(v:event.completed_item)
  call easycomplete#popup#StartCheck(a:info)
  let s:info = a:info
endfunction

function! easycomplete#popup#CompleteDone()
  let s:item = copy(v:completed_item)
  call easycomplete#popup#close()
endfunction

function! easycomplete#popup#StartCheck(info)
  " use timer_start since nvim_buf_set_lines is not allowed in
  " CompleteChanged
  " call easycomplete#util#StopAsyncRun()
  call easycomplete#util#AsyncRun(function('s:check'), [a:info], 0)
endfunction

function! s:check(info)
  if empty(s:item) || empty(a:info) || !pumvisible()
    call easycomplete#popup#close()
    return
  endif
  if g:easycomplete_popup_win && s:event == s:last_event
    " let s:skip_cnt = get(s:, 'skip_cnt', 0) + 1
    " echom 'already opened, skip ' . s:skip_cnt
    return
  endif
  let s:last_event = s:event

  let info = type(a:info) == type("") ? [a:info] : a:info

  if !s:buf
    if s:is_vim
      noa let s:buf = bufadd('')
      noa call bufload(s:buf)
      call setbufvar(s:buf, '&filetype', &filetype)
    elseif s:is_nvim
      noa let s:buf = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_option(s:buf, 'syntax', 'on')
      call nvim_buf_set_option(s:buf, 'filetype', &filetype)
    endif
    call setbufvar(s:buf, '&buflisted', 0)
    call setbufvar(s:buf, '&buftype', 'nofile')
    call setbufvar(s:buf, '&undolevels', -1)
  endif

  if s:is_nvim
    call nvim_buf_set_lines(s:buf, 0, -1, v:false, info)
  elseif s:is_vim
    call deletebufline(s:buf, 1, '$')
    call setbufline(s:buf, 1, info)
  endif

  let prevw_width = easycomplete#popup#DisplayWidth(info, g:easycomplete_popup_width)
  let prevw_height = easycomplete#popup#DisplayHeight(info, prevw_width) - 1

  let opt = { 
        \ 'focusable': v:true,
        \ 'width': prevw_width,
        \ 'height': prevw_height,
        \ 'relative':'editor',
        \ 'style':'minimal'
        \ }

  " {{{ show relative popup
  if s:event.scrollbar
    let right_avail_col  = s:event.col + s:event.width + 1
  else
    let right_avail_col  = s:event.col + s:event.width
  endif
  " -1 for zero-based indexing, -1 for vim's popup menu padding
  let left_avail_col = s:event.col - 2

  let right_avail = &co - right_avail_col
  let left_avail = left_avail_col + 1

  if right_avail >= prevw_width
    let opt.col = right_avail_col
  elseif left_avail >= prevw_width
    let opt.col = left_avail_col - prevw_width + 1
  else
    " no enough space to displace the preview window
    call easycomplete#popup#close()
    return
  endif
  " }}}

  if winline() < s:event.row
    " 菜单向下展开
    let opt.row = s:event.row
  else
    " 菜单向上展开
    let opt.row = winline() - opt.height
  endif

  " close the old one if already opened
  call easycomplete#popup#close()

  if s:is_nvim
    call s:NvimShowPopup(opt)
  elseif s:is_vim
    call s:VimShowPopup(opt)
  endif
endfunction

function! s:VimShowPopup(opt)
  if s:is_nvim | return | endif
  let opt = {
        \ 'line': a:opt.row + 1,
        \ 'col': a:opt.col + 1,
        \ 'maxwidth': a:opt.width,
        \ 'maxheight': a:opt.height,
        \ 'firstline': 0,
        \ 'fixed': 1
        \ }
  if g:easycomplete_popup_win
    call easycomplete#popup#close()
  endif
  let winid = popup_create(s:buf, opt)
  call setbufvar(s:buf, "&filetype", &filetype)
  call setwinvar(winid, '&scrolloff', 0)
  call setwinvar(winid, 'float', 1)
  call setwinvar(winid, '&list', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&relativenumber', 0)
  call setwinvar(winid, '&cursorcolumn', 0)
  call setwinvar(winid, '&colorcolumn', 0)
  call setwinvar(winid, '&wrap', 1)
  call setwinvar(winid, '&linebreak', 1)
  call setwinvar(winid, '&conceallevel', 2)
  let g:easycomplete_popup_win = winid
  call popup_show(g:easycomplete_popup_win)
endfunction

function! s:NvimShowPopup(opt)
  if s:is_vim | return | endif
  let winargs = [s:buf, 0, a:opt]
  let g:easycomplete_popup_win = call('nvim_open_win', winargs)
  call nvim_win_set_var(g:easycomplete_popup_win, 'syntax', 'on')
  call nvim_win_set_option(g:easycomplete_popup_win, 'foldenable', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'wrap', v:true)
  call nvim_win_set_option(g:easycomplete_popup_win, 'statusline', '')
  call nvim_win_set_option(g:easycomplete_popup_win, 'winhl', 'Normal:Pmenu,NormalNC:Pmenu')
  call nvim_win_set_option(g:easycomplete_popup_win, 'number', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'relativenumber', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'cursorline', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'cursorcolumn', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'colorcolumn', '')
  if has('nvim-0.5.0')
    call setwinvar(g:easycomplete_popup_win, '&scrolloff', 0)
  endif

  silent doautocmd <nomodeline> User FloatPreviewWinOpen
endfunction

function! easycomplete#popup#reopen()
  call easycomplete#popup#close()
  call easycomplete#popup#StartCheck(s:info)
endfunction

function! easycomplete#popup#close()
  if s:is_vim
    if g:easycomplete_popup_win
      call popup_close(g:easycomplete_popup_win)
      let g:easycomplete_popup_win = 0
    endif
  else
    if g:easycomplete_popup_win
      let id = win_id2win(g:easycomplete_popup_win)
      if id > 0
        execute id . 'close!'
      endif
      let g:easycomplete_popup_win = 0
      let s:last_winargs = []
    endif
  endif
endfunction

function! easycomplete#popup#DisplayWidth(lines, max_width)
  let width = 0
  for line in a:lines
    let w = strdisplaywidth(line)
    if w < a:max_width
      if w > width
        let width = w
      endif
    else
      let width = a:max_width
    endif
  endfor
  return width
endfunction

function! easycomplete#popup#DisplayHeight(lines, width)
  " 1 for padding
  let height = 1

  for line in a:lines
    let height += (strdisplaywidth(line) + a:width - 1) / a:width
  endfor
  let max_height = s:max_height
  return height > max_height ? max_height : height
endfunction


function! s:log(msg)
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction
