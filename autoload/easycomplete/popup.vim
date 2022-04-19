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
" 6. popup 和 float 应当分开
"     - popup 只给completemenu显示 info 使用
"     - float 用作signature和diagnostics

" popup window 最大高度
let s:popup_max_height = 50
let s:float_max_height = 15
let s:is_vim = !has('nvim')
let s:is_nvim = has('nvim')
" signature/lint
let s:float_type = "signature"

augroup easycomplete#popup#au
  autocmd!
  autocmd VimResized * call easycomplete#popup#reopen()
  autocmd BufLeave * call easycomplete#popup#close()
  autocmd BufWinLeave * call easycomplete#popup#close()
  autocmd WinLeave * call easycomplete#popup#close()
  autocmd InsertLeave * call easycomplete#popup#close()
  if s:is_nvim
    autocmd VimResume * call easycomplete#popup#reopen()
  endif
augroup END

let s:timer = 0
let g:easycomplete_popup_win = {
      \ "popup" : 0,
      \ "float" : 0
      \ }
let s:event = {}
let s:item = {}
let s:info = []

let s:last_event = {}
let s:last_winargs = []
let s:buf = {
      \ "popup":0,
      \ "float":0,
      \ }

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
  call easycomplete#popup#close("popup")
endfunction

function! easycomplete#popup#test()
  let content = [
        \ "~/.vim/bundle/vim-easycomplete/autoload/easycomplete/popup.vim [+] [utf-8]",
        \ "asdkjfo ajodij aojf aojf a;fj alfj",
        \ "testing testing"]
  call easycomplete#popup#float(content, 'ErrorMsg', 0, "python", [0,0], 'signature')
endfunction

" content, hl, direction: 0, 向下，1，向上
" ft, 文件类型
" offset, 偏移量，正常跟随光标传入[0,0], [line(),col()]
" float_type: signature/lint
function! easycomplete#popup#float(content, hl, direction, ft, offset, float_type)
  if type(a:content) == type('')
    let content = [a:content]
  elseif type(a:content) == type([])
    let content = a:content
  else
    return
  endif
  let float_maxwidth = 80
  let content = easycomplete#util#ModifyInfoByMaxwidth(content, float_maxwidth)
  if len(content) == 1 && strlen(content[0]) == 0
    return
  endif
  let prevw_width = easycomplete#popup#DisplayWidth(content, float_maxwidth)
  let prevw_height = easycomplete#popup#DisplayHeight(content, prevw_width, 'float') - 1
  call s:InitBuf(content, 'float', a:ft)
  let opt = extend({
        \   'relative':'editor',
        \   'focusable': v:true,
        \   'style':'minimal',
        \   'filetype': empty(a:ft) ? "help" : a:ft
        \ },
        \ {
        \   'width': prevw_width,
        \   'height': prevw_height,
        \ })
  " handle height
  let screen_enc = (win_screenpos(win_getid())[0] - 1)
  if !a:direction " 正常向下
    if winline() + prevw_height <= winheight(win_getid())
      " 菜单向下展开ok
      let opt.row = winline() + 1 + screen_enc
    elseif winline() + prevw_height >= winheight(win_getid())
          \ && prevw_height >= 3
          \ && winheight(win_getid()) - winline() >= 3
      " 压缩float框向下展开
      let opt.height = winheight(win_getid()) - winline()
      let opt.row = winline() + 1 + screen_enc
    else
      " 菜单向上展开
      let opt.row = winline() - prevw_height + screen_enc
    endif
  else " 正常向上
    if winheight(win_getid()) - winline() + 1 + prevw_height <= winheight(win_getid())
      " 单窗口内空间足够，菜单向上展开 ok
      let opt.row = winline() - prevw_height + screen_enc
    elseif winheight(win_getid()) - winline() + prevw_height + 1 > winheight(win_getid())
          \ && prevw_height >= 3
          \ && winline() >= 4
      " 单窗口内向上展开所需空间不够，要判断窗口上方还有没有多余空间
      let t_pos = screen_enc + ((winline() - prevw_height) -1)
      if t_pos >= 0
        " 占用顶部空间全部展开
        let opt.height = prevw_height
        let opt.row = t_pos + 1
      else
        " 占用顶部空间也不够展示，则向上压缩展开
        let opt.height = prevw_height + t_pos
        let opt.row = 1
      endif
    else  " 单窗口内向下展开
      " 先判断顶部是否有多余的空间给与展示
      let t_pos = screen_enc + ((winline() - prevw_height) -1)
      if t_pos >= 0
        " 顶部还有空，用顶部空间全部展开
        let opt.height = prevw_height
        let opt.row = t_pos + 1
      else
        " 顶部空间仍然不够，则菜单向下展开
        let opt.row = winline() + 1 + screen_enc
      endif
    endif
  endif
  let opt.row -= 1

  let screen_col_enc = win_screenpos(win_getid())[1] - 1
  let opt.col = screen_col_enc + wincol() - 1
  let opt.col += a:offset[1]
  " TODO col 方向的offset的处理ok，line方向的offset未做处理
  " handle width
  if opt.col + prevw_width > winwidth(win_getid()) + screen_col_enc - 1
    let opt.col = screen_col_enc + winwidth(win_getid()) - prevw_width
  elseif opt.col < 0
    " 如果叠加 offset 之后，左侧超出边界，则直接赋值为 0
    let opt.col = 0
  endif

  if !empty(a:hl)
    let opt.highlight = a:hl
  endif

  if s:is_nvim
    call easycomplete#popup#close("float")
    call s:NVimShow(opt, "float", a:float_type)
  elseif s:is_vim
    call s:VimShow(opt, "float", a:float_type)
  endif
endfunction

" 这里只判断complete menu和float 之间是否有overlay
" 如果有overlay，则关闭float
" 在completedone之后调用
" 这里简化一下，只判断Y轴上是否有重叠
function! easycomplete#popup#overlay()
  if s:IsOverlay()
    call easycomplete#popup#close("float")
  endif
endfunction

function! s:IsOverlay()
  let float_winid = g:easycomplete_popup_win['float']
  if empty(float_winid) | return v:false | endif
  if empty(pum_getpos()) | return v:false | endif
  let float_config = getwininfo(float_winid)[0]
  let pum_config = pum_getpos()
  let overlay = v:false
  if float_config.height != 1
    if pum_config.row <= float_config.winrow
          \ && pum_config.row + pum_config.height - 1 >= float_config.winrow
      let overlay = v:true
    endif
    if pum_config.row <= float_config.winrow + float_config.height - 1
          \ && pum_config.row + pum_config.height - 1 >= float_config.winrow + float_config.height - 1
      let overlay = v:true
    endif
  endif
  let screen_line = winline() + (win_screenpos(win_getid())[0] - 1)
  if (pum_config.row > screen_line && float_config.winrow > screen_line)
        \ || (pum_config.row < screen_line && float_config.winrow < screen_line)
        \ || (pum_config.row == screen_line && float_config.winrow > screen_line)
    let overlay = v:true
  endif
  return overlay
endfunction

function! easycomplete#popup#DoPopup(info)
  call s:StopVisualAsyncRun()
  call s:StartPopupAsyncRun("s:popup", [a:info], 170)
endfunction

" s:popup 代替 popup_info 方法，只给 completion 使用
" 外部调用时统一使用 easycomplete#popup#float() 方法
function! s:popup(info)
  if !pumvisible() || !easycomplete#CompleteCursored()
    call easycomplete#popup#close("popup")
    return
  endif
  if empty(s:item) || empty(a:info)
    if s:is_vim
      call popup_hide(g:easycomplete_popup_win["popup"])
    else
      call easycomplete#popup#close("popup")
    endif
    return
  endif
  if s:is_nvim && g:easycomplete_popup_win["popup"] && s:event == s:last_event
    return
  endif
  let s:last_event = s:event

  let info = type(a:info) == type("") ? [a:info] : a:info
  let info = easycomplete#util#ModifyInfoByMaxwidth(info, g:easycomplete_popup_width)

  if len(info) == 1 && len(info[0]) == 0
    if s:is_vim
      call popup_hide(g:easycomplete_popup_win["popup"])
    else
      call easycomplete#popup#close("popup")
    endif
    return
  endif
  call s:InitBuf(info, 'popup', &filetype)
  let prevw_width = easycomplete#popup#DisplayWidth(info, g:easycomplete_popup_width)
  let prevw_height = easycomplete#popup#DisplayHeight(info, prevw_width, 'popup') - 1
  let opt = {
        \ 'focusable': v:true,
        \ 'width': prevw_width,
        \ 'height': prevw_height,
        \ 'relative':'editor',
        \ 'style':'minimal',
        \ 'filetype': &filetype
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
    call easycomplete#popup#close("popup")
    return
  endif

  let l:screen_line = winline() + (win_screenpos(win_getid())[0] - 1)
  let screen_enc = (win_screenpos(win_getid())[0] - 1)
  if l:screen_line <= s:event.row
    " 菜单向下展开
    let opt.row = s:event.row
    let opt.row = winline() + screen_enc
  else
    " 菜单向上展开
    let opt.row = l:screen_line - opt.height - 1
    if s:is_nvim
      let opt.row += 0
    endif
  endif

  if s:is_nvim
    call easycomplete#popup#close("popup")
    call s:NVimShow(opt, "popup", '')
  elseif s:is_vim
    call s:VimShow(opt, "popup", '')
  endif
endfunction

" info: content
" buftype: float/popup
" ft: filetype
function! s:InitBuf(info, buftype, ft)
  let ft = empty(a:ft) ? &filetype : a:ft
  if !s:buf[a:buftype]
    if s:is_vim
      noa let s:buf[a:buftype] = bufadd('')
      noa call bufload(s:buf[a:buftype])
      noa call setbufvar(s:buf[a:buftype], '&filetype', ft)
    elseif s:is_nvim
      let s:buf[a:buftype] = nvim_create_buf(v:false, v:true)
      call nvim_buf_set_option(s:buf[a:buftype], 'filetype', ft)
      call nvim_buf_set_option(s:buf[a:buftype], 'syntax', 'on')
    endif
    call setbufvar(s:buf[a:buftype], '&buflisted', 0)
    call setbufvar(s:buf[a:buftype], '&buftype', 'nofile')
    call setbufvar(s:buf[a:buftype], '&undolevels', -1)
  endif

  if s:is_nvim
    call nvim_buf_set_lines(s:buf[a:buftype], 0, -1, v:false, a:info)
  elseif s:is_vim
    noa silent call deletebufline(s:buf[a:buftype], 1, '$')
    noa silent call setbufline(s:buf[a:buftype], 1, a:info)
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

" windowtype: float/popup
function! s:VimShow(opt, windowtype, float_type)
  if s:is_nvim | return | endif
  let opt = {
        \ 'filetype': a:opt.filetype,
        \ 'line': a:opt.row + 1,
        \ 'col': a:opt.col + 1,
        \ 'maxwidth': a:opt.width,
        \ 'maxheight': a:opt.height,
        \ 'firstline': 0,
        \ 'fixed': 1,
        \ }
  if exists('a:opt.highlight')
    let opt.highlight = a:opt.highlight
  else
    let opt.highlight = 'Pmenu'
  endif

  " TODO: 在 iTerm2 下，执行 popup_move/popup_setoptions/popup_create 会造成
  " complete menu 的闪烁，原因未知
  let winid = g:easycomplete_popup_win[a:windowtype]
  if opt.filetype == "lua"
    " lua documentation 中包含大量注释，妨碍阅读，改成 help
    let opt.filetype = "help"
  endif
  if winid != 0
    call setwinvar(winid, '&wincolor', opt.highlight)
    call popup_setoptions(winid, opt)
    call popup_show(winid)
  else
    noa let winid = popup_create(s:buf[a:windowtype], opt)
    noa let g:easycomplete_popup_win[a:windowtype] = winid
    " ano silent call setwinvar(winid, '&scrolloff', 1)
    " ano silent call setwinvar(winid, 'float', 1)
    " ano silent call setwinvar(winid, '&number', 0)
    " call setwinvar(winid, '&list', 0)
    " call setwinvar(winid, '&cursorcolumn', 0)
    " call setwinvar(winid, '&colorcolumn', 0)
    " call setwinvar(winid, '&wrap', 1)
    " call setwinvar(winid, '&linebreak', 1)
    " call setwinvar(winid, '&conceallevel', 2)
  endif
  " Popup and Signature
  if a:windowtype == 'popup' || (a:windowtype == "float" && a:float_type == "signature")
    call setbufvar(winbufnr(winid), '&filetype', opt.filetype)
    call easycomplete#ui#ApplyMarkdownSyntax(winid)
  else
    " Lint
    call setbufvar(winbufnr(winid), '&filetype', 'txt')
  endif
endfunction

function! s:NVimShow(opt, windowtype, float_type)
  if s:is_vim | return | endif
  if exists('a:opt.highlight')
    let hl = a:opt.highlight
    unlet a:opt.highlight
  else
    let hl = 'Pmenu'
  endif
  let filetype = &filetype == "lua" ? "help" : &filetype
  let hl_str = 'Normal:' . hl . ',NormalNC:' . hl
  let winargs = [s:buf[a:windowtype], 0, a:opt]
  unlet winargs[2].filetype
  noa let winid = nvim_open_win(s:buf[a:windowtype], 0, winargs[2])
  let g:easycomplete_popup_win[a:windowtype] = winid
  call nvim_win_set_var(g:easycomplete_popup_win[a:windowtype], 'syntax', 'on')
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'winhl', hl_str)
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'number', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'relativenumber', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'cursorline', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'cursorcolumn', v:false)
  call nvim_win_set_option(g:easycomplete_popup_win[a:windowtype], 'colorcolumn', '')
  if has('nvim-0.5.0')
    call setwinvar(g:easycomplete_popup_win[a:windowtype], '&scrolloff', 0)
  endif
  " Popup and Signature
  if a:windowtype == 'popup' || (a:windowtype == "float" && a:float_type == "signature")
    call setbufvar(winbufnr(winid), '&filetype', filetype)
  else
    " Lint
    call setbufvar(winbufnr(winid), '&filetype', 'txt')
  endif
  if a:windowtype == "float" && a:float_type == "signature"
    call easycomplete#ui#ApplyMarkdownSyntax(winid)
  endif
endfunction

function! easycomplete#popup#reopen()
  call easycomplete#popup#close("popup")
  call easycomplete#popup#DoPopup(s:info)
endfunction

function! easycomplete#popup#visiable()
  if g:easycomplete_popup_win["popup"] || g:easycomplete_popup_win["float"]
    return v:true
  endif
  return v:false
endfunction

function! easycomplete#popup#close(...)
  if empty(a:000)
    if g:easycomplete_popup_win["popup"]
      call easycomplete#popup#close("popup")
    endif
    if g:easycomplete_popup_win["float"]
      call easycomplete#popup#close("float")
    endif
    return
  endif
  let windowtype = a:1
  if windowtype == "float" &&
        \ bufnr() != expand("<abuf>") &&
        \ !empty(expand("<abuf>")) &&
        \ pumvisible() &&
        \ easycomplete#util#InsertMode()
    return
  endif
  if s:is_vim
    if g:easycomplete_popup_win[windowtype]
      call popup_close(g:easycomplete_popup_win[windowtype])
      let g:easycomplete_popup_win[windowtype] = 0
    endif
  else
    if g:easycomplete_popup_win[windowtype]
      let id = win_id2win(g:easycomplete_popup_win[windowtype])
      if id > 0
        let winid = g:easycomplete_popup_win[windowtype]
        call timer_start(50, { -> s:NvimCloseFloatWithPum(winid) })
      endif
      let g:easycomplete_popup_win[windowtype] = 0
      let s:last_winargs = []
    endif
  endif
endfunction

function! s:NvimCloseFloatWithPum(winid)
  if nvim_win_is_valid(a:winid)
    call nvim_win_close(a:winid, 1)
  endif
  if pumvisible() && s:IsOverlay()
    let winid = g:easycomplete_popup_win['float']
    if winid != 0
      if nvim_win_is_valid(winid)
        call nvim_win_close(winid, 1)
      endif
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

function! easycomplete#popup#DisplayHeight(lines, width, type)
  " 1 for padding
  let height = 1
  " for line in a:lines
  "   let height += (strdisplaywidth(line) + a:width - 1) / a:width
  " endfor
  let height = len(a:lines) + 1
  if a:type == "float"
    let max_height = s:float_max_height
  else
    let max_height = s:popup_max_height
  endif
  return height > max_height ? max_height : height
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:trace(...)
  return call('easycomplete#util#trace', a:000)
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction
