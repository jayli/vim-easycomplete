" for nvim only

let s:pum_window = 0
let s:pum_buffer = 0

function! easycomplete#pum#complete(startcol, items)
  call s:CreateWindow(a:startcol, s:NormalizeItems(a:items))
endfunction

function! s:CreateWindow(startcol, lines)
  call s:InitBuffer()
  let buffer_size = s:GetBufSize(a:lines)
  let pum_pos = s:GetPumPos(a:startcol, buffer_size)
  let opts = {"relative": "win"}
  call extend(opts, pum_pos)
  call s:console(opts)
  let winid = nvim_open_win(s:pum_buffer, v:false, opts)
  call nvim_win_set_option(winid, 'winhl', 'Normal:Pmenu,NormalNC:Pmenu')
  call setwinvar(winid, '&scrolloff', 0)
  call setwinvar(winid, '&spell', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&wrap', 0)
  call setwinvar(winid, '&signcolumn', "no")
  call setwinvar(winid, '&cursorline', 0)
  call nvim_buf_set_lines(s:pum_buffer, 0, -1, v:false, a:lines)
  let s:pum_window = winid
endfunction

" 根据起始位置和buffer的大小，计算Pum应该有的大小和位置，返回 options
function! s:GetPumPos(startcol, buffer_size)
  let cursor_line = line(".")
  return {"row": cursor_line, "col": a:startcol,
        \ "width":  a:buffer_size.width,
        \ "height": a:buffer_size.height
        \ }
endfunction

function! s:flush()
  if nvim_win_is_valid(s:pum_window)
    call nvim_win_close(s:pum_window, 1)
  endif
  let s:pum_window = 0
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
  return map(copy(a:items), 'v:val["word"]')
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
