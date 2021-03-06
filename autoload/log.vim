

augroup log#Config
  let s:debugger = {}
  let s:debugger.status = 'stop'
  let s:debugger.original_winnr = winnr()
  let s:debugger.original_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.original_winid = bufwinid(bufnr(""))
  let s:debugger.log_bufinfo = 0
  let s:debugger.log_winid = -20
  let s:debugger.log_winnr = 0
augroup END

augroup log#Augroup
  autocmd!
  autocmd QuitPre * call log#quit()
augroup END

function! log#log(msg)
  call s:initLogWindow()
  call s:printLog([string(a:msg)])
  call s:scrollLogWinToBottom()
endfunction

function! s:logRunning()
  return argc(s:debugger.log_winid) == -1 ? 0 : 1
endfunction

function! s:initLogWindow()
  let s:debugger.original_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.original_winid = bufwinid(bufnr(""))

  if s:logRunning()
    return
  endif

  call execute("vertical botright new")
  call execute("setlocal nonu")
  let s:debugger.log_winnr = winnr()
  let s:debugger.log_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.log_winid = bufwinid(bufnr(""))

  let log_bufnr = get(s:debugger,'log_bufinfo')[0].bufnr
  call setbufvar(log_bufnr, '&modifiable', 0)
  call s:gotoOriginalWindow()
endfunction

function! s:emptyLogWindow()
  if s:logRunning()
    let log_bufnr = get(s:debugger,'log_bufinfo')[0].bufnr
    call setbufvar(log_bufnr, '&modifiable', 1)
    call s:deletebufline(log_bufnr, 1, len(getbufline(log_bufnr, 0,'$')))
    call setbufvar(localvar_bufnr, '&modifiable', 0)
  endif
endfunction " }}}

function! log#quit()
  if get(s:debugger, 'log_winid') == bufwinid(bufnr(""))
    call execute(':q!', 'silent!')
  endif
  if get(s:debugger, 'original_winid') == bufwinid(bufnr(""))
    call s:closeLogWindow()
    call feedkeys("\<S-ZZ>")
  endif
endfunction

function! s:closeLogWindow()
  call s:gotoLogWindow()
  call execute(':q!', 'silent!')
endfunction

function! s:printLog(content)
  if s:logRunning()
    let bufnr = get(s:debugger,'log_bufinfo')[0].bufnr
    echom bufnr
    call s:renderLog(bufnr, a:content)
    let s:debugger.log_bufinfo = getbufinfo(bufnr)
  endif
endfunction

function! s:renderLog(buf, content)
  if empty(a:content)
    return
  endif
  let l:content = a:content
  let bufnr = a:buf
  let buf_oldlnum = len(getbufline(bufnr,0,'$'))
  call setbufvar(bufnr, '&modifiable', 1)
  let ix = buf_oldlnum
  for item in l:content
    let ix = ix + 1
    call setbufline(bufnr, ix, item)
  endfor
  call setbufvar(bufnr, '&modifiable', 0)
  call feedkeys("\<ESC>","n")
  call s:gotoLogWindow()
  call s:gotoOriginalWindow()
endfunction

function! s:scrollLogWinToBottom()
  let m = mode()
  if index(['i','ic','ix'], m) >= 0
    call feedkeys("\<ESC>","n")
  endif
  call s:gotoLogWindow()
  normal! G
  call s:gotoOriginalWindow()
  if index(['i','ic','ix'], m) >= 0
    call feedkeys("a","n")
    call execute('redraw','silent!')
  endif
  " call setwinvar(s:debugger.log_winnr, "move",
  "       \ len(getbufline(get(s:debugger,'log_bufinfo')[0].bufnr ,0,'$')))
endfunction

function! s:deletebufline(bn, fl, ll)
  if exists("deletebufline")
    call deletebufline(a:bn, a:fl, a:ll)
  else
    let current_winid = bufwinid(bufnr(""))
    call s:gotoWindow(bufwinid(a:bn))
    call execute(string(a:fl) . 'd ' . string(a:ll - a:fl), 'silent!')
    call g:gotoWindow(current_winid)
  endif
endfunction

function! s:gotoWindow(winid) abort
  if a:winid == bufwinid(bufnr(""))
    return
  endif
  for window in range(1, winnr('$'))
    call s:gotoWinnr(window)
    if a:winid == bufwinid(bufnr(""))
      break
    endif
  endfor
endfunction

function! s:gotoWinnr(winnr) abort
  let cmd = type(a:winnr) == type(0) ? a:winnr . 'wincmd w'
        \ : 'wincmd ' . a:winnr
  noautocmd execute cmd
  call execute('redraw','silent!')
endfunction

function! s:gotoOriginalWindow()
  call s:gotoWindow(s:debugger.original_winid)
endfunction

function! s:gotoLogWindow()
  call s:gotoWindow(s:debugger.log_winid)
endfunction


