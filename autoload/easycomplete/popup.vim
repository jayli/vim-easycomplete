" nvim only
if get(s:, 'easycompelte_popup_loaded') || !has('nvim')
  finish
endif
let s:easycompelte_popup_loaded = 1

augroup easycomplete#popup#au
  autocmd!
  autocmd CompleteDone * call easycomplete#popup#CompleteDone()
  autocmd InsertLeave * call easycomplete#popup#InsertLeave()
  autocmd VimResized,VimResume * call easycomplete#popup#reopen()
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
  if empty(s:item) || !pumvisible()
    call easycomplete#popup#close()
    return
  endif
  if g:easycomplete_popup_win && s:event == s:last_event
    " let s:skip_cnt = get(s:, 'skip_cnt', 0) + 1
    " echom 'already opened, skip ' . s:skip_cnt
    return
  endif
  let s:last_event = s:event

  let info = a:info

  " if type(info) == type("") && (empty(info) || info ==# "_")
  "   call easycomplete#popup#close()
  "   return
  " endif

  " if type(info) == type([]) && empty(info)
  "   call easycomplete#popup#close()
  "   return
  " endif

  let info = type(info) == type("") ? [info] : info

  if !s:buf
    " unlisted-buffer & scratch-buffer (nobuflisted, buftype=nofile,
    " bufhidden=hide, noswapfile)
    let s:buf = nvim_create_buf(0, 1)
    call nvim_buf_set_option(s:buf, 'syntax', 'OFF')
  endif
  call nvim_buf_set_lines(s:buf, 0, -1, 0, info)

  let prevw_width = easycomplete#popup#DisplayWidth(info, g:easycomplete_popup_width)
  let prevw_height = easycomplete#popup#DisplayHeight(info, prevw_width) - 1

  let opt = { 'focusable': v:true,
        \ 'width': prevw_width,
        \ 'height': prevw_height,
        \ 'relative':'editor',
        \ 'style':'minimal'
        \}

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

  " let opt.row = s:event.row

  if winline() < s:event.row
    " 菜单向下展开
    let opt.row = s:event.row
  else
    " 菜单向上展开
    let opt.row = winline() - opt.height
  endif

  " if winline() > s:event:row
  "   " 菜单向上展开
  "   let opt.row = winline() - 1 - opt.height
  " endif

  let winargs = [s:buf, 0, opt]

  " close the old one if already opened
  call easycomplete#popup#close()

  let g:easycomplete_popup_win = call('nvim_open_win', winargs)
  call nvim_win_set_option(g:easycomplete_popup_win, 'foldenable', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'wrap', v:true)
  call nvim_win_set_option(g:easycomplete_popup_win, 'statusline', '')
  call nvim_win_set_option(g:easycomplete_popup_win, 'winhl', 'Normal:Pmenu,NormalNC:Pmenu')
  call nvim_win_set_option(g:easycomplete_popup_win, 'number', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'relativenumber', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'cursorline', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'cursorcolumn', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win, 'colorcolumn', '')
  call nvim_win_set_option(g:easycomplete_popup_win, 'filetype', 'javascript')
  call nvim_win_set_option(g:easycomplete_popup_win, 'syntax', 'on')

  silent doautocmd <nomodeline> User FloatPreviewWinOpen
endfunction

function! easycomplete#popup#reopen()
  call easycomplete#popup#close()
  call easycomplete#popup#StartCheck(s:info)
endfunction

function! easycomplete#popup#close()
  if g:easycomplete_popup_win
    let id = win_id2win(g:easycomplete_popup_win)
    if id > 0
      execute id . 'close!'
    endif
    let g:easycomplete_popup_win = 0
    let s:last_winargs = []
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
  let max_height = 40
  return height > max_height ? max_height : height
endfunction


