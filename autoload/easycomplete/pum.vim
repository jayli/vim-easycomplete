" for nvim only
let s:default_pum_pot = {
        \ "relative": "editor",
        \ "focusable": v:false,
        \ "zindex": 50,
        \ "bufpos": [0,0]
        \ }
let s:default_scroll_pot = {
        \ "relative": "editor",
        \ "focusable": v:false,
        \ "zindex": 51,
        \ "bufpos": [0,0]
        \ }
let s:pum_window = 0
let s:pum_buffer = 0
let s:pum_direction = ""

" scrollbar vars
let s:scrollbar_window = 0
let s:scrollbar_buffer = 0
let s:has_scrollbar = 0
" complete_info() 中 selected 从 0 开始，这里从 1 开始
" easycomplete#pum#CompleteInfo() 的返回和 complete_info() 保持一致
let s:selected_i = 0
let s:curr_items = []
" 类似 b:typing_ctx，为了避免干扰，这里只给 pum 使用
let s:original_ctx = {}
" 当前编辑窗口的原始配置
let s:original_opt = {}

" window 内高度，不包含tabline和statusline: winheight(win_getid())
" 当前window的起始位置，算上了 tabline: win_screenpos(win_getid())
" cursor所在位置相对window顶部的位置，不包含tabline: winline()
" cursor所在位置相对window到底部的位置，
" screen 整个视口高度，&window
" cursor 相对 screen 顶部的高度(含当前 cursor): win_screenpos(win_getid())[0] + winline() - 1
" cursor 相对 screen 底部的高度(含当前 cursor 和 statusline): &lines - (win_screenpos(win_getid())[0] + winline() - 1)
" cursor 相对 screen 左侧的距离(含当前cursor)，win_screenpos(win_getid())[1] + wincol() - 1

function! easycomplete#pum#complete(startcol, items)
  if len(a:items) == 0
    call s:close()
    return
  endif
  let s:curr_items = deepcopy(a:items)
  call s:OpenPum(a:startcol, s:NormalizeItems(a:items))
endfunction

function! s:hl()
  let hl_name = "easycomplete_pum_hl"
  let exec_cmd = [
        \ 'syntax region AAA matchgroup=Conceal start=/\%(``\)\@!`/ matchgroup=Conceal end=/\%(``\)\@!`/ concealends',
        \ 'syntax region BBB matchgroup=Conceal start=/\%(||\)\@!|/ matchgroup=Conceal end=/\%(||\)\@!|/ concealends',
        \ "hi AAA guifg=red",
        \ "hi BBB guifg=lightblue",
        \ ]
  call win_execute(s:pum_window, join(exec_cmd, "\n"))
endfunction

function! s:OpenPum(startcol, lines)
  " call add(a:lines, "`sdf`,|sdfsdf|,*sdfsfs* s df")
  call s:InitBuffer(a:lines)
  let buffer_size = s:GetBufSize(a:lines)
  let pum_pos = s:ComputePumPos(a:startcol, buffer_size)
  let pum_opts = deepcopy(s:default_pum_pot)
  call extend(pum_opts, pum_pos)
  if empty(s:pum_window)
    call s:CacheOpt()
    let hl = 'Normal:Pmenu,NormalNC:Pmenu,CursorLine:PmenuSel'
    let winid = s:OpenFloatWindow(s:pum_buffer, pum_opts, hl)
    let s:pum_window = winid
    call s:hl()
    let s:original_ctx = b:typing_ctx
  else
    " 已经存在的 windowid 用 nvim_win_set_config
    call nvim_win_set_config(s:pum_window, pum_opts)
    doautocmd <nomodeline> User easycomplete_pum_completechanged
  endif
  call s:reset()
  call s:RenderScrollbar()
  call nvim_win_set_cursor(s:pum_window, [1, 0])
endfunction

function! easycomplete#pum#WinScrolled()
  if !s:pumvisible() | return | endif
  if has_key(v:event, bufwinid(bufnr("")))
    " 编辑窗口的移动
    let cursor_left = s:CursorLeft()
    let typing_word = easycomplete#util#GetTypingWord()
    let new_startcol = getcurpos()[2] - strlen(typing_word)
    let lines = getbufline(s:pum_buffer, 1, "$")
    let buffer_size = s:GetBufSize(lines)
    let pum_pos = s:ComputePumPos(new_startcol, buffer_size)
    let opts = deepcopy(s:default_pum_pot)
    call extend(opts, pum_pos)
    call nvim_win_set_config(s:pum_window, opts)
    let curr_item = easycomplete#pum#CursoredItem()
    if !empty(curr_item)
      call easycomplete#ShowCompleteInfoByItem(curr_item)
    endif
  endif
  if has_key(v:event, s:pum_window)
    call s:RenderScrollbar()
  endif
endfunction

function! easycomplete#pum#GetPos()
  return s:GetPumPos()
endfunction

function! s:CacheOpt()
  let s:original_opt = {
        \ "hlsearch": &hlsearch,
        \ "wrap": &wrap,
        \ "spell": &spell
        \ }
endfunction

function! s:RestoreOpt()
  call setwinvar(0, '&hlsearch', get(s:original_opt, "hlsearch"))
  call setwinvar(0, '&wrap', get(s:original_opt, "wrap"))
  call setwinvar(0, '&spell', get(s:original_opt, "spell"))
endfunction

function! s:SelectNext()
  if !s:pumvisible() | return | endif
  let item_length = len(s:curr_items)
  let next_i = 0
  if s:selected_i == item_length
    let next_i = 0
  else
    let next_i = s:selected_i + 1
  endif
  call s:select(next_i)
  let s:selected_i = next_i
  call easycomplete#zizz()
  doautocmd <nomodeline> User easycomplete_pum_completechanged
endfunction

function! easycomplete#pum#CompleteChangedEvnet()
  let l:event = {}
  if !s:pumvisible() || !easycomplete#pum#CompleteCursored()
    return l:event
  endif
  let completed_item = easycomplete#pum#CursoredItem()
  let pum_pos = s:GetPumPos()
  let h = pum_pos.height
  let w = pum_pos.width
  let r = pum_pos.pos[0]
  let c = pum_pos.pos[1]
  let scrollbar = s:HasScrollbar()
  if scrollbar
    let w = w - 1
  endif
  let item_size = len(s:curr_items)
  return {
        \ "completed_item": completed_item,
        \ "col": c + 1,
        \ "row": r,
        \ "height": h,
        \ "width": w - 1,
        \ "scrollbar": scrollbar,
        \ "size": item_size
        \}
endfunction

function! s:SelectPrev()
  if !s:pumvisible() | return | endif
  let item_length = len(s:curr_items)
  let prev_i = 0
  if s:selected_i == 1
    let prev_i = 0
  elseif s:selected_i == 0
    let prev_i = item_length
  else
    let prev_i = s:selected_i - 1
  endif
  call s:select(prev_i)
  let s:selected_i = prev_i
  doautocmd <nomodeline> User easycomplete_pum_completechanged
endfunction

function! easycomplete#pum#next()
  call s:SelectNext()
endfunction

function! easycomplete#pum#prev()
  call s:SelectPrev()
endfunction

function! easycomplete#pum#CompleteCursored()
  return s:selected_i == 0 ? v:false : v:true
endfunction

function! easycomplete#pum#CompleteInfo()
  let l:ret = {
        \ "mode": "function",
        \ "pum_visible": s:pumvisible() ? v:true : v:false,
        \ "items": s:curr_items,
        \ "selected": s:selected_i - 1,
        \ }
  return l:ret
endfunction

function! easycomplete#pum#CursoredItem()
  if !s:pumvisible() | return {} | endif
  if s:selected_i == 0 | return {} | endif
  return s:curr_items[s:selected_i - 1]
endfunction

function! s:select(line_index)
  if !s:pumvisible() | return | endif
  if a:line_index > len(s:curr_items)
    let l:line_index = (a:line_index + len(s:curr_items)) % len(s:curr_items)
  else
    let l:line_index = a:line_index
  endif
  if l:line_index == 0
    call setwinvar(s:pum_window, '&cursorline', 0)
    let s:selected_i = 0
  else
    call setwinvar(s:pum_window, '&cursorline', 1)
    call nvim_win_set_cursor(s:pum_window, [l:line_index, 1])
    let s:selected_i = l:line_index
  endif
endfunction

" TAB 和 S-TAB 的过程中对单词的自动补全动作，返回一个需要操作的字符串
function! easycomplete#pum#SetWordBySelecting()
  let pum_pos = s:GetPumPos()
  let cursor_left = s:CursorLeft()
  let backing_count = cursor_left - pum_pos.pos[1] - 2 
  let oprator_str = repeat("\<bs>", backing_count)
  if !easycomplete#pum#CompleteCursored()
    return oprator_str . get(s:original_ctx, "typing", "")
  else
    return oprator_str . get(s:curr_items[s:selected_i - 1], "word", "")
  endif
endfunction

function! easycomplete#pum#select(line_index)
  call s:select(a:line_index)
endfunction

" Cursor 距离 screen top 的位置，含 cursor 的位置，算上了 tabline
function! s:CursorTop()
  return win_screenpos(win_getid())[0] + winline() - 1
endfunction

" Cursor 距离 screen bottom 的位置，含 cursor 的位置，算上了 statusline
function! s:CursorBottom()
  return &lines - s:CursorTop()
endfunction

" Cursor 距离 screen left 的位置，含 cursor 的位置
function! s:CursorLeft()
  return win_screenpos(win_getid())[1] + wincol() - 1
endfunction

function! s:CursorRight()
  return &columns - s:CursorLeft()
endfunction

function! easycomplete#pum#CursorLeft()
  return s:CursorLeft()
endfunction

function! s:CreateEmptyBuffer()
  let local_buffer = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_option(local_buffer, 'filetype', "txt")
  call nvim_buf_set_option(local_buffer, 'syntax', 'on')
  call setbufvar(local_buffer, '&buflisted', 0)
  call setbufvar(local_buffer, '&buftype', 'nofile')
  call setbufvar(local_buffer, '&undolevels', -1)
  return local_buffer
endfunction

function! s:OpenFloatWindow(buf, opts, hl)
  let winid = nvim_open_win(a:buf, v:false, a:opts)
  call setwinvar(winid, '&winhl', a:hl)
  call setwinvar(winid, '&scrolloff', 0)
  call setwinvar(winid, '&spell', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&wrap', 0)
  call setwinvar(winid, '&signcolumn', "no")
  call setwinvar(winid, '&hlsearch', 0)
  call setwinvar(winid, '&list', 0)
  call setwinvar(winid, '&conceallevel', 3)
  return winid
endfunction

function! s:RenderScrollbar()
  if !s:pumvisible() || !s:HasScrollbar()
    call s:CloseScrollBar()
    return
  endif
  if empty(s:scrollbar_buffer)
    let s:scrollbar_buffer = s:CreateEmptyBuffer()
    let buflines = s:GetScrollBufflines()
    call nvim_buf_set_lines(s:scrollbar_buffer, 0, -1, v:false, buflines)
  endif
  let scrollbar_pos = s:ComputeScrollPos()
  let scrollbar_opts = deepcopy(s:default_scroll_pot)
  call extend(scrollbar_opts, scrollbar_pos)
  if empty(s:scrollbar_window)
    " create scroll window
    let hl = "Normal:PmenuSbar,NormalNC:PmenuSbar,CursorLine:PmenuSbar"
    let s:scrollbar_window = s:OpenFloatWindow(s:scrollbar_buffer, scrollbar_opts, hl)
  else
    " update scroll window
    call nvim_win_set_config(s:scrollbar_window, scrollbar_opts)
  endif
endfunction

function! s:GetScrollBufflines()
  return repeat([" "], len(s:curr_items))
endfunction

function! s:ComputeScrollPos()
  let pum_pos = s:GetPumPos()
  let c = pum_pos.pos[1] + pum_pos.width - 1
  let r = pum_pos.pos[0]
  let w = 1
  " ---- 计算 scrollbar 的高度 ----
  let buf_h = len(s:curr_items)
  let pum_h = pum_pos.height
  let scroll_h = float2nr(floor(pum_h * pum_h * 1.0 / buf_h))
  if scroll_h >= pum_h
    let scroll_h = pum_h
  endif
  let h = scroll_h
  " ---- 计算scrollbar 的位置 ----
  let top_line = getwininfo(s:pum_window)[0]["topline"]
  let max_off_r = pum_h - scroll_h
  let max_top_line = buf_h - pum_h + 1
  if top_line == 1
    let r = pum_pos.pos[0]
  elseif top_line >= max_top_line
    let r = pum_pos.pos[0] + max_off_r
  else
    let p_position = (top_line - 1) * 1.0 / (buf_h - pum_h)
    let r_position = float2nr((pum_h * p_position * 1.0) - (scroll_h * 1.0 / 2))
    if r_position < 0
      let r_position = 0
    elseif r_position >= max_off_r
      let r_position = max_off_r
    endif

    if r_position == 0 && top_line > 1
      let r_position = 1
    elseif r_position == max_off_r && top_line < max_top_line
      let r_position = max_off_r - 1
    endif
    let r = pum_pos.pos[0] + r_position
  endif

  return { "col": c, "row": r, "width": w, "height": h }
endfunction

function! s:CloseScrollBar()
  if !empty(s:scrollbar_window) && nvim_win_is_valid(s:scrollbar_window)
    call nvim_win_close(s:scrollbar_window, 1)
  endif
  let s:scrollbar_window = 0
endfunction

function! s:HasScrollbar()
  return s:has_scrollbar == 1 ? v:true : v:false
endfunction

function! s:GetPumPos()
  if s:pumvisible()
    let pos = nvim_win_get_position(s:pum_window)
    let h = nvim_win_get_height(s:pum_window)
    let w = nvim_win_get_width(s:pum_window)
    return {"pos":pos, "height": h, "width": w}
  else
    return {}
  endif
endfunction

" 判断 PUM 是向上展示还是向下展示
function! s:PumDirection(buffer_height)
  let buffer_height = a:buffer_height
  let below_space = s:CursorBottom() - 1
  
  " 如果底部空间不够
  if buffer_height > below_space
    if below_space < 6 " 底部空间太小，小于 6，一律在上部展示
      return "above"
    elseif below_space >= 10 " 底部空间大于等于10，一律在底部展示
      return "below"
    elseif buffer_height - below_space <= 5 " 底部空间只藏了5个及以内的item，可以在底部展示
      return "below"
    else " 底部空间不够且溢出5个以上的 item，就展示在上部
      return "above"
    endif
  else " 如果底部空间足够
    return "below"
  endif
endfunction

" 根据起始位置和buffer的大小，计算Pum应该有的大小和位置，返回 options
function! s:ComputePumPos(startcol, buffer_size)
  let pum_direction = s:PumDirection(a:buffer_size.height)
  let s:pum_direction = pum_direction
  let l:height = 0
  let l:width = a:buffer_size.width
  let l:row = 0
  if pum_direction == "below"
    let below_space = s:CursorBottom() - 1
    if a:buffer_size.height >= below_space " 需要滚动
      let l:height = below_space
    else
      let l:height = a:buffer_size.height
    endif
    let l:row = s:CursorTop()
  endif
  if pum_direction == "above"
    let above_space = s:CursorTop() - 1
    if a:buffer_size.height >= above_space " 需要滚动
      let l:height = above_space
    else
      let l:height = a:buffer_size.height
    endif
    let l:row = s:CursorTop() - l:height - 1
  endif
  if l:height < a:buffer_size.height
    " 判断是否应该出现 scrollbar
    let s:has_scrollbar = 1
    let l:width = a:buffer_size.width + 1
  else
    let s:has_scrollbar = 0
  endif
  " 计算相对于 editor 的 startcol
  let offset = col('.') - a:startcol
  let realcol = s:CursorLeft() - offset
  " 如果触碰到右壁，默认缩短，和 vim 保持一致，永远和字符对齐
  let right_space = &columns - (realcol - 2)
  if right_space < l:width
    let l:width = right_space
  endif
  return {"row": l:row, "col": realcol - 2,
        \ "width":  l:width,
        \ "height": l:height
        \ }
endfunction

" secondcomplete 过程中有可能手动移动了 pum 的 cursor，继续 typing
" 时需要reset一下状态 
function! s:reset()
  if !(&completeopt=~"noselect")
    call s:select(1)
  else
    call s:select(0)
  endif
endfunction

function! s:flush()
  let should_fire_pum_done = 0
  if !empty(s:pum_window) && nvim_win_is_valid(s:pum_window)
    call nvim_win_close(s:pum_window, 1)
    call s:RestoreOpt()
    let should_fire_pum_done = 1
  endif
  if !empty(s:scrollbar_window)
    call s:CloseScrollBar()
  endif
  let s:pum_window = 0
  let s:has_scrollbar = 0
  let s:selected_i = 0
  let s:curr_items = []
  let s:original_ctx = {}
  let s:scrollbar_window = 0
  let s:pum_direction = ""
  if should_fire_pum_done
    doautocmd <nomodeline> User easycomplete_pum_done
  endif
endfunction

function! s:close()
  call s:flush()
endfunction

function! easycomplete#pum#close()
  call s:flush()
endfunction

function! s:pumvisible()
  return s:pum_window > 0 ? v:true : v:false
endfunction

function! easycomplete#pum#visible()
  return s:pumvisible()
endfunction

function! s:InitBuffer(lines)
  if empty(s:pum_buffer)
    let pum_buffer = s:CreateEmptyBuffer()
    let s:pum_buffer = pum_buffer
  endif
  call nvim_buf_set_lines(s:pum_buffer, 0, -1, v:false, a:lines)
endfunction

function! s:GetBufSize(lines)
  let buffer_width = s:MaxLength(a:lines) + 1
  let buffer_height = len(a:lines)
  return {"width": buffer_width, "height": buffer_height}
endfunction

function! s:MaxLength(lines)
  let max_length = 0
  for item in a:lines
    let curr_length = strdisplaywidth(item)
    if curr_length > max_length
      let max_length = curr_length
    endif
  endfor
  return max_length
endfunction

function! s:NormalizeItems(items)
  let new_line_arr = s:GetFullfillItems(a:items)
  return map(copy(new_line_arr["items"]), function('s:MapFunction'))
endfunction

function! s:MapFunction(key, val)
  let ret = [
        \ " ",
        \ get(a:val, "abbr", ""), " ",
        \ get(a:val, "kind", ""), " ",
        \ get(a:val, "menu", ""),
        \ ]
  return join(ret,"")
endfunction

function! s:GetFullfillItems(data)
  let wlength = 0
  let word_arr_length = []
  let kind_arr_length = []
  let menu_arr_length = []
  let abbr_arr_length = []
  let new_data = []
  for item in a:data
    let abbr = easycomplete#util#GetItemAbbr(item)
    let word = get(item, "word", "")
    if empty(get(item, "abbr", ""))
      let item["abbr"] = abbr
    endif
    let word_arr_length += [strdisplaywidth(word)]
    let abbr_arr_length += [strdisplaywidth(abbr)]
    let kind_arr_length += [strdisplaywidth(trim(get(item, "kind", "")))]
    let menu_arr_length += [strdisplaywidth(trim(get(item, "menu", "")))]
  endfor
  let maxlength = {
        \ "word_max_length": max(word_arr_length),
        \ "abbr_max_length": max(abbr_arr_length),
        \ "kind_max_length": max(kind_arr_length),
        \ "menu_max_length": max(menu_arr_length)
        \ }
  for item in a:data
    let f_kind = s:fullfill(trim(get(item, "kind", "")), maxlength.kind_max_length)
    let f_menu = s:fullfill(trim(get(item, "menu", "")), maxlength.menu_max_length)
    call add(new_data, {
          \ "abbr": s:fullfill(get(item, "abbr", ""), maxlength.abbr_max_length),
          \ "word": s:fullfill(get(item, "word", ""), maxlength.word_max_length),
          \ "kind": f_kind,
          \ "menu": f_menu
          \ })
  endfor
  return extend({
        \ "items": new_data,
        \ }, maxlength)
endfunction

function! s:fullfill(word, length)
  let word_length = strdisplaywidth(a:word)
  if word_length >= a:length
    return a:word
  endif
  let inc = a:length - word_length
  return a:word . repeat(" ", inc)
endfunction

function! easycomplete#pum#fullfill(word, length)
  return s:fullfill(a:word, a:length)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:get(...)
  return call('easycomplete#util#get', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:trace(...)
  return call('easycomplete#util#trace', a:000)
endfunction
