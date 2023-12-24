" for nvim only

let s:pum_window = 0
let s:scroll_bar = 0
let s:pum_buffer = 0
let s:selected_i = 0
let s:curr_items = []

" window 内高度，不包含tabline和statusline: winheight(win_getid())
" 当前window的起始位置，算上了 tabline: win_screenpos(win_getid())
" cursor所在位置相对window顶部的位置，不包含tabline: winline()
" cursor所在位置相对window到底部的位置，
" screen 整个视口高度，&window
" cursor 相对 screen 顶部的高度(含当前 cursor): win_screenpos(win_getid())[0] + winline() - 1
" cursor 相对 screen 底部的高度(含当前 cursor 和 statusline): &lines - (win_screenpos(win_getid())[0] + winline() - 1)

function! easycomplete#pum#complete(startcol, items)
  let s:curr_items = deepcopy(a:items)
  call s:CreateWindow(a:startcol, s:NormalizeItems(a:items))
endfunction

function! s:CreateWindow(startcol, lines)
  call s:InitBuffer()
  let buffer_size = s:GetBufSize(a:lines)
  let pum_pos = s:ComputePumPos(a:startcol, buffer_size)
  let opts = {
        \ "relative": "win",
        \ "focusable": v:false
        \ }
  call extend(opts, pum_pos)
  let winid = nvim_open_win(s:pum_buffer, v:false, opts)
  call nvim_win_set_option(winid, 'winhl', 'Normal:Pmenu,NormalNC:Pmenu,CursorLine:PmenuSel')
  call setwinvar(winid, '&scrolloff', 0)
  call setwinvar(winid, '&spell', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&wrap', 0)
  call setwinvar(winid, '&signcolumn', "no")
  if !(&completeopt=~"noselect")
    call setwinvar(winid, '&cursorline', 1)
  else
    call setwinvar(winid, '&cursorline', 0)
  endif
  call nvim_buf_set_lines(s:pum_buffer, 0, -1, v:false, a:lines)
  let s:pum_window = winid
  if s:HasScrollbar()
    call s:InitScrollBar()
  endif
endfunction

function! s:select(line_index)
  if !s:pumvisible() | return | endif
  if a:line_index > len(s:curr_items)
    let l:line_index = a:line_index % len(s:curr_items)
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

" TODO
function! s:InitScrollBar()
  if !s:pumvisible() | return | endif
  let window_info = s:WindowInfo()
endfunction

function! s:HasScrollbar()
  return s:scroll_bar == 1 ? v:true : v:false
endfunction

function! s:WindowInfo()
  if s:pumvisible()
    let pos = nvim_win_get_position(s:pum_window)
    let h = nvim_win_get_height(s:pum_window)
    let w = nvim_win_get_width(s:pum_window)
    return {"pos":pos, "height": h, "width": w}
  else
    return {}
  endif
endfunction

function! s:CompleteInfo()

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
    let l:row = s:CursorTop() - 1
  endif
  if pum_direction == "above"
    let above_space = s:CursorTop() - 1
    if a:buffer_size.height >= above_space
      let l:height = above_space
    else
      let l:height = a:buffer_size.height
    endif
    let l:row = s:CursorTop() - l:height - 2
  endif
  if l:height < a:buffer_size.height
    " 判断是否应该出现 scrollbar
    let s:scroll_bar = 1
    let l:width = a:buffer_size.width + 1
  else
    let s:scroll_bar = 0
  endif
  return {"row": l:row, "col": a:startcol + s:PaddingLeft() - 2,
        \ "width":  l:width,
        \ "height": l:height 
        \ }
endfunction

function! s:PaddingLeft()
  let original_width = 0
  if &signcolumn == "yes"
    let original_width = original_width + 2
  endif
  if &number == 1
    let original_width = original_width + &numberwidth
  endif
  return original_width
endfunction

function! s:flush()
  if nvim_win_is_valid(s:pum_window)
    call nvim_win_close(s:pum_window, 1)
  endif
  let s:pum_window = 0
  let s:scroll_bar = 0
  let s:selected_i = 0
  let s:curr_items = []
endfunction

function! s:pumvisible()
  return s:pum_window > 0 ? v:true : v:false
endfunction

function! s:InitBuffer()
  if empty(s:pum_buffer)
    let pum_buffer = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_option(pum_buffer, 'filetype', "txt")
    call nvim_buf_set_option(pum_buffer, 'syntax', 'on')
    call setbufvar(pum_buffer, '&buflisted', 0)
    call setbufvar(pum_buffer, '&buftype', 'nofile')
    call setbufvar(pum_buffer, '&undolevels', -1)
    let s:pum_buffer = pum_buffer
  endif
endfunction

function! s:GetBufSize(lines)
  let buffer_width = s:MaxLength(a:lines) + 2
  let buffer_height = len(a:lines)
  return {"width": buffer_width, "height": buffer_height}
endfunction

function! s:MaxLength(lines)
  let max_length = 0
  for item in a:lines
    let curr_length = strlen(item)
    if curr_length > max_length
      let max_length = curr_length
    endif
  endfor
  return max_length
endfunction

function! s:NormalizeItems(items)
  return map(copy(a:items), '" " . v:val["word"]')
endfunction

function! s:GetBaseParam(data)
  let wlength = 0
  let word_arr_length = []
  let kind_arr_length = []
  let menu_arr_length = []
  let new_data = []
  for item in a:data
    let abbr = get(item, "abbr", "")
    let word = empty(abbr) ? get(item, "word", "") : abbr
    let word_arr_length += [strlen(word)]
    let kind_arr_length += [strlen(get(item, "kind", ""))]
    let menu_arr_length += [strlen(get(item, "menu", ""))]
  endfor
  let maxlength = {
        \ "word_max_length": max(word_arr_length),
        \ "kind_max_length": max(kind_arr_length),
        \ "menu_max_length": max(menu_arr_length)
        \ }
  for item in a:data
    call add(new_data, {
          \ "abbr": s:fullfill(get(item, "abbr", ""), maxlength.word_max_length),
          \ "word": s:fullfill(get(item, "word", ""), maxlength.word_max_length),
          \ "kind": s:fullfill(get(item, "kind", ""), maxlength.kind_max_length),
          \ "menu": s:fullfill(get(item, "menu", ""), maxlength.menu_max_length)
          \ })
  endfor
  return extend({
        \ "items": new_data,
        \ },
        \ {
        \ "word_max_length": max(word_arr_length),
        \ "kind_max_length": max(kind_arr_length),
        \ "menu_max_length": max(menu_arr_length)
        \ })
endfunction

function! s:fullfill(word, length)
  let word_length = strlen(a:word)
  if word_length >= a:length
    return a:word
  endif
  let inc = a:length - word_length
  return a:word . repeat(" ", inc)
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
