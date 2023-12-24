" for nvim only

let s:pum_window = 0
let s:pum_buffer = 0

function! easycomplete#pum#complete()
  call s:CreateWindow(4, ["abc","def","sdkksdf","sdfjiijx dii","sd0ocxi"])
endfunction

function! s:CreateWindow(startcol, lines)
  call s:InitBuffer()
  let opts = {"relative":'win', "row":3, "col":a:startcol, "width":12, "height":10}
  let winid = nvim_open_win(s:pum_buffer, v:false, opts)
  call nvim_win_set_option(winid, 'winhl', 'Normal:Pmenu,NormalNC:Pmenu')
  call setwinvar(winid, '&scrolloff', 0)
  call setwinvar(winid, '&spell', 0)
  call setwinvar(winid, '&number', 0)
  call setwinvar(winid, '&wrap', 0)
  call setwinvar(winid, '&signcolumn', "no")
  call setwinvar(winid, '&cursorline', 0)
  call nvim_buf_set_lines(s:pum_buffer, 0, -1, v:false, a:lines)
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

function! easycomplete#pum#normalize(...)
  let data = a:0 ? a:1 : []
  let data = easycomplete#lua#data()
  let base_param = s:GetBaseParam(data)
  let word_max_length = base_param["word_max_length"]
  let kind_max_length = base_param["kind_max_length"]
  let menu_max_length = base_param["menu_max_length"]
  let pum_height = len(data)
  let pum_width = word_max_length + kind_max_length + menu_max_length + 5
  call s:log(base_param.items)
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
