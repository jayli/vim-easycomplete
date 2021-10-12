" Popup menu 的实现 <bachi@taobao.com>
" vim 8.2 实现了 popupmenu, 即 completeopt+=popup 很好用，但有几个bug
" 1. setlocal completepopup=width:70 中的 Width 属性无效
" 2. 连续 c-n 快速在 completemenu 中移动选中位置，频繁 popup 出 infomenu
" 时会有 complete menu 的闪烁
" 3. menu info 字段不支持 list 类型
" 4. 按照官方文档手工通过 popup_settext 和 popup_show 来显示 popup window
" 的话，必须通过 popup_findinfo 来获取已经存在的 popup window，但
" popup_findinfo 必须被存在 info 不为空的 complete item 高亮时先创建出来，否则
" popup_findinfo 的结果是空，如果这时手工创建 popup window，popup_findinfo 依
" 然无法返回手工创建的这个 window id，还不如全部手写 popup 逻辑
" 5. nvim 没有实现 popup menu 的功能，但提供了浮窗能力，因此干脆手写了

" popup window 最大高度
let s:max_height = 40
let s:is_vim = !has('nvim')
let s:is_nvim = has('nvim')

augroup easycomplete#popup#au
  autocmd!
  autocmd VimResized * call easycomplete#popup#reopen()
  if s:is_nvim
    autocmd VimResume * call easycomplete#popup#reopen()
  endif
augroup END

let s:timer = 0
let g:easycomplete_popup_win = 0
let s:event = {}
let s:item = {}
let s:info = []

let s:last_event = {}
let s:last_winargs = []
let s:buf = 0
let s:hl = {
      \   'diagnostics': {
      \     'error':'ErrorMsg',
      \     'warning':'WarningMsg',
      \     'information':'Pmenu',
      \     'hint':'Pmenu'
      \   },
      \ }

function! easycomplete#popup#InsertLeave()
  call easycomplete#popup#close()
endfunction

function! easycomplete#popup#MenuPopupChanged(info)
  if empty(v:event) && empty(g:easycomplete_completechanged_event) | return | endif
  let s:event = empty(v:event) ? copy(g:easycomplete_completechanged_event) : copy(v:event)
  let s:item = has_key(v:event, 'completed_item') ?
        \ copy(v:event.completed_item) : copy(easycomplete#GetCompletedItem())

  call easycomplete#popup#DoPopup(a:info)
  let s:info = a:info
endfunction

function! easycomplete#popup#CompleteDone()
  let s:item = copy(v:completed_item)
  call easycomplete#popup#close()
endfunction

function! easycomplete#popup#test()
  let content = [
        \ "~/.vim/bundle/vim-easycomplete/autoload/easycomplete/popup.vim [+] [utf-8]",
        \ "asdkjfo ajodij aojf aojf a;fj alfj",
        \ "testing testing"]
  call easycomplete#popup#show(content, 'ErrorMsg', 0)
endfunction

" content, hl, direction: 0, 向下，1，向上
function! easycomplete#popup#show(content, hl, direction)
  if type(a:content) == type('')
    let content = [a:content]
  elseif type(a:content) == type([])
    let content = a:content
  else
    return
  endif
  let prevw_width = easycomplete#popup#DisplayWidth(content, 80)
  let prevw_height = easycomplete#popup#DisplayHeight(content, prevw_width) - 1
  call s:InitPopupBuf(content)
  let opt = extend({
        \   'relative':'editor',
        \   'focusable': v:true,
        \   'style':'minimal'
        \ },
        \ {
        \   'width': prevw_width,
        \   'height': prevw_height,
        \ })
  " handle height
  if !a:direction
    if winline() + prevw_height <= winheight(win_getid())
      " 菜单向下展开
      let opt.row = winline() + 1
    else
      " 菜单向上展开
      let opt.row = winline() - prevw_height
    endif
  else
    if winheight(win_getid()) - winline() + prevw_height > winheight(win_getid())
      " 菜单向下展开
      let opt.row = winline() + 1
    else
      " 菜单向上展开
      let opt.row = winline() - prevw_height
    endif
  endif

  " handle width
  if wincol() + prevw_width - 1 > winwidth(win_getid())
    let opt.col = winwidth(win_getid()) - prevw_width
  else
    let opt.col = wincol() - 1
  endif

  if !empty(a:hl)
    let opt.highlight = a:hl
  endif

  if s:is_nvim
    call easycomplete#popup#close()
    call s:NvimShowPopup(opt)
  elseif s:is_vim
    call s:VimShowPopup(opt)
  endif
endfunction

function! easycomplete#popup#DoPopup(info)
  call s:StopVisualAsyncRun()
  call s:StartPopupAsyncRun("s:popup", [a:info], 170)
endfunction

" s:popup 代替 popup_info 方法
" 外部调用时使用 easycomplete#popup#show() 方法
function! s:popup(info)
  if !pumvisible()
    call easycomplete#popup#close()
    return
  endif
  if empty(s:item) || empty(a:info)
    if s:is_vim
      call popup_hide(g:easycomplete_popup_win)
    else
      call easycomplete#popup#close()
    endif
    return
  endif
  if s:is_nvim && g:easycomplete_popup_win && s:event == s:last_event
    return
  endif
  let s:last_event = s:event

  let info = type(a:info) == type("") ? [a:info] : a:info
  call s:InitPopupBuf(info)
  let prevw_width = easycomplete#popup#DisplayWidth(info, g:easycomplete_popup_width)
  let prevw_height = easycomplete#popup#DisplayHeight(info, prevw_width) - 1

  let opt = {
        \ 'focusable': v:true,
        \ 'width': prevw_width,
        \ 'height': prevw_height,
        \ 'relative':'editor',
        \ 'style':'minimal'
        \ }

  if get(s:event, 'scrollbar')
    let right_avail_col  = s:event.col + s:event.width + 1
  else
    let right_avail_col  = s:event.col + s:event.width
  endif
  let left_avail_col = s:event.col - 2

  let right_avail = &co - right_avail_col
  let left_avail = left_avail_col + 1

  if right_avail >= prevw_width
    let opt.col = right_avail_col
  elseif left_avail >= prevw_width
    let opt.col = left_avail_col - prevw_width + 1
  else
    " 无更多空间，直接关闭
    call easycomplete#popup#close()
    return
  endif

  let l:screen_line = line('.') - line('w0') + 1
  if l:screen_line <= s:event.row
    " 菜单向下展开
    let opt.row = s:event.row
  else
    " 菜单向上展开
    let opt.row = l:screen_line - opt.height - 1
    let opt.row += (win_screenpos(win_getid())[0] - 1)
    if s:is_nvim
      let opt.row += 0
    endif
  endif

  if s:is_nvim
    call easycomplete#popup#close()
    call s:NvimShowPopup(opt)
  elseif s:is_vim
    call s:VimShowPopup(opt)
  endif
endfunction

function! s:InitPopupBuf(info)
  if !s:buf
    if s:is_vim
      let s:buf = bufadd('')
      call bufload(s:buf)
      call setbufvar(s:buf, '&filetype', &filetype)
    elseif s:is_nvim
      let s:buf = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_option(s:buf, 'filetype', &filetype)
      call nvim_buf_set_option(s:buf, 'syntax', 'on')
    endif
    call setbufvar(s:buf, '&buflisted', 0)
    call setbufvar(s:buf, '&buftype', 'nofile')
    call setbufvar(s:buf, '&undolevels', -1)
  endif

  if s:is_nvim
    call nvim_buf_set_lines(s:buf, 0, -1, v:false, a:info)
  elseif s:is_vim
    call deletebufline(s:buf, 1, '$')
    call setbufline(s:buf, 1, a:info)
    " call setbufline(s:buf, 1, [rand(srand())])
  endif
endfunction

function! s:StopVisualAsyncRun()
  if exists('s:popup_visual_delay') && s:popup_visual_delay > 0
    call timer_stop(s:popup_visual_delay)
  endif
endfunction

function! s:StartPopupAsyncRun(method, args, times)
  let s:popup_visual_delay = timer_start(a:times,
        \ { -> easycomplete#util#call(function(a:method), a:args)})
endfunction

function! s:VimShowPopup(opt)
  if s:is_nvim | return | endif
  let opt = {
        \ 'line': a:opt.row + 1,
        \ 'col': a:opt.col + 1,
        \ 'maxwidth': a:opt.width,
        \ 'maxheight': a:opt.height,
        \ 'firstline': 0,
        \ 'fixed': 1,
        \ }
  if exists('a:opt.highlight')
    let opt.highlight = a:opt.highlight
  endif

  " TODO: 在 iTerm2 下，执行 popup_move/popup_setoptions/popup_create 会造成
  " complete menu 的闪烁，原因未知
  if g:easycomplete_popup_win
    call popup_setoptions(g:easycomplete_popup_win, opt)
    call popup_show(g:easycomplete_popup_win)
  else
    let winid = popup_create(s:buf, opt)
    let g:easycomplete_popup_win = winid
    call setwinvar(winid, '&scrolloff', 1)
    call setwinvar(winid, 'float', 1)
    call setwinvar(winid, '&number', 0)
    " call setwinvar(winid, '&list', 0)
    " call setwinvar(winid, '&cursorcolumn', 0)
    " call setwinvar(winid, '&colorcolumn', 0)
    " call setwinvar(winid, '&wrap', 1)
    " call setwinvar(winid, '&linebreak', 1)
    " call setwinvar(winid, '&conceallevel', 2)
  endif
endfunction

function! s:NvimShowPopup(opt)
  if s:is_vim | return | endif
  if exists('a:opt.highlight')
    let hl = a:opt.highlight
    unlet a:opt.highlight
  else
    let hl = 'Pmenu'
  endif
  let hl_str = 'Normal:' . hl . ',NormalNC:' . hl
  let winargs = [s:buf, 0, a:opt]
  let g:easycomplete_popup_win = call('nvim_open_win', winargs)
  call nvim_win_set_var(g:easycomplete_popup_win, 'syntax', 'on')
  call nvim_win_set_option(g:easycomplete_popup_win, 'winhl', hl_str)
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
  call easycomplete#popup#DoPopup(s:info)
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

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
