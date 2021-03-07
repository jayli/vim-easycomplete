" log#log() authored by jayli bachi@taobao.com
" Useage
"   - Command
"     - Log {stn} : show low at window
"     - CleanLog  : Clean the log window
"     - CloseLog  : Close the log window
"   - API
"     - log#log(...): print logs
"   - Global config
"     - g:vim_log_enabled = 1   enable log at side window
"     - g:vim_log_enabled = 0   disable log printing

augroup log#Config
  let s:debugger = {}
  let s:debugger.logfile = 0
  let s:debugger.status = 'stop'
  let s:debugger.original_winnr = winnr()
  let s:debugger.original_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.original_winid = bufwinid(bufnr(""))
  let s:debugger.log_bufinfo = 0
  let s:debugger.log_winid = -20
  let s:debugger.log_winnr = 0
  let s:debugger.log_term_winid = 0
  let s:debugger.init_msg = [
        \ " ____________________________________",
        \ "|                                    |",
        \ "|                                    |",
        \ "| Use <C-C> here to close log window |",
        \ "| Authored by Jayli bachi@taobao.com |",
        \ "|                                    |",
        \ "|____________________________________|"]

augroup END

augroup log#Augroup
  autocmd!
  autocmd QuitPre * call log#quit()

  command! -nargs=0 -complete=command CleanLog call log#clean()
  command! -nargs=0 -complete=command CloseLog call log#close()
  command! -nargs=1 -complete=command Log call log#log(<args>)
augroup END

" 多参数适配
function! log#log(...)
  if !exists('g:vim_log_enabled')
    let g:vim_log_enabled = 1
  endif

  if g:vim_log_enabled != 1
    return
  endif

  let l:args = a:000
  let l:res = ""
  if empty(a:000)
    let l:res = ""
  elseif len(a:000) == 1
    let l:res = a:1
  else
    for item in l:args
      let l:res = l:res . " " . json_encode(item)
    endfor
  endif
  if executable('tail')
    call s:InitLogFile()
    call s:InitLogWindow()
    call s:AppendLog(l:res)
  else
    call call(s:log, a:000)
  endif
endfunction

function! s:LogRunning()
  return argc(s:debugger.log_winid) == -1 ? 0 : 1
endfunction

function! s:InitLogWindow()
  let s:debugger.original_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.original_winid = bufwinid(bufnr(""))
  if s:LogRunning()
    return
  endif
  call execute("vertical botright new filetype=help buftype=nofile")
  call execute("setlocal nonu")
  call term_start("tail -f " . get(s:debugger, 'logfile'),{
      \ 'term_finish': 'close',
      \ 'term_name':'log_debugger_window_name',
      \ 'vertical':'1',
      \ 'curwin':'1'
      \ })
  exec 'setl statusline=%1*\ Normal\ %*%5*\ Log\ Window\ %*\ %r%f[%M]%=Depth\ :\ %L\ '
  let s:debugger.log_term_winid = bufwinid('log_debugger_window_name')
  let s:debugger.log_winnr = winnr()
  let s:debugger.log_bufinfo = getbufinfo(bufnr(''))
  let s:debugger.log_winid = bufwinid(bufnr(""))
  call s:AppendLog(copy(get(s:debugger, 'init_msg')))
  call s:GotoOriginalWindow()
endfunction

function! s:EmptyLogWindow()
  call s:CloseLogWindow()
  call s:DelLogFile()
  call log#log()
endfunction

function! log#clean()
  call s:EmptyLogWindow()
endfunction

function! log#close()
  if s:LogRunning()
    call s:CloseLogWindow()
  endif
endfunction

function! log#quit()
  if get(s:debugger, 'log_winid') == bufwinid(bufnr(""))
    call term_sendkeys("log_debugger_window_name","\<C-C>")
  endif
  if get(s:debugger, 'original_winid') == bufwinid(bufnr(""))
    if s:LogRunning()
      call s:CloseLogWindow()
      call feedkeys("\<S-ZZ>")
    endif
  endif
  call s:DelLogFile()
endfunction

function! s:CloseLogWindow()
  if s:LogRunning()
    call s:GotoLogWindow()
    call execute(':q!', 'silent!')
  endif
endfunction

function! s:AppendLog(content)
  if empty(a:content)
    return
  endif

  if type(a:content) == type([])
    let l:content = a:content
  else
    let l:content = [a:content]
  endif
  call map(l:content, { key, val -> '>>> ' . val})
  if s:LogRunning()
    let l:logfile = get(s:debugger, "logfile")
    call writefile(l:content, l:logfile, "a")
  endif
endfunction

function! s:InitLogFile()
  let l:logfile = get(s:debugger, 'logfile')
  if !empty(l:logfile)
    return l:logfile
  endif
  let s:debugger.logfile = tempname()
  call writefile([""], s:debugger.logfile, "a")
  return s:debugger.logfile
endfunction

function! s:DelLogFile()
  let l:logfile = get(s:debugger, 'logfile')
  if !empty(l:logfile)
    call delete(l:logfile)
    let s:debugger.logfile = 0
  endif
endfunction

function! s:GotoWindow(winid) abort
  if a:winid == bufwinid(bufnr(""))
    return
  endif
  for window in range(1, winnr('$'))
    call s:GotoWinnr(window)
    if a:winid == bufwinid(bufnr(""))
      break
    endif
  endfor
endfunction

function! s:GotoWinnr(winnr) abort
  let cmd = type(a:winnr) == type(0) ? a:winnr . 'wincmd w'
        \ : 'wincmd ' . a:winnr
  noautocmd execute cmd
  call execute('redraw','silent!')
endfunction

function! s:GotoOriginalWindow()
  call s:GotoWindow(s:debugger.original_winid)
endfunction

function! s:GotoLogWindow()
  call s:GotoWindow(s:debugger.log_term_winid)
endfunction

function! s:log(...)
  let l:args = a:000
  let l:res = ""
  for item in l:args
    l:res = l:res . " " . string(item)
  endfor
  echohl MoreMsg
  echom '>>> '. l:res
  echohl NONE
endfunction
