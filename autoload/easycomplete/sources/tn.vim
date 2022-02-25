if exists('g:easycomplete_tn')
  finish
endif
let g:easycomplete_tn = 1

let s:tn_job = v:null
let s:ctx = v:null
let s:name = ''
let s:tn_ready = v:false


function! easycomplete#sources#tn#constructor(opt, ctx)
  let name = get(a:opt, "name", "")
  let s:name = name
  if !easycomplete#installer#LspServerInstalled(name)
    return v:true
  endif
  call s:StartTabNine()
  return v:true
endfunction

function! easycomplete#sources#tn#available()
  return s:tn_ready
endfunction

function! easycomplete#sources#tn#completor(opt, ctx) abort
  if !s:tn_ready
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif



  let l:config = {'line_limit': 1000, 'max_num_result': 10}
  let l:line_limit = 1000
  let l:max_num_result = 10
  let l:pos = getpos('.')
  let l:last_line = line('$')
  let l:before_line = max([1, l:pos[1] - l:line_limit])
  let l:before_lines = getline(l:before_line, l:pos[1])
  if !empty(l:before_lines)
    let l:before_lines[-1] = l:before_lines[-1][:l:pos[2]-1]
  endif
  let l:after_line = min([l:last_line, l:pos[1] + l:line_limit])
  let l:after_lines = getline(l:pos[1], l:after_line)
  if !empty(l:after_lines)
    let l:after_lines[0] = l:after_lines[0][l:pos[2]:]
  endif

  let l:region_includes_beginning = v:false
  if l:before_line == 1
    let l:region_includes_beginning = v:true
  endif

  let l:region_includes_end = v:false
  if l:after_line == l:last_line
    let l:region_includes_end = v:true
  endif

  let l:params = {
     \   'filename': a:ctx['filepath'],
     \   'before': join(l:before_lines, "\n"),
     \   'after': join(l:after_lines, "\n"),
     \   'region_includes_beginning': l:region_includes_beginning,
     \   'region_includes_end': l:region_includes_end,
     \   'max_num_result': l:max_num_result,
     \ }
  " TODO here
  " call s:request('Autocomplete', l:params, a:opt, a:ctx)



  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  return v:true
endfunction

function! s:StartTabNine()
  if empty(s:name)
    return
  endif
  let name = s:name
  let l:tabnine_path = easycomplete#installer#GetCommand(name)
  let l:log_file = fnameescape(fnamemodify(l:tabnine_path, ':p:h')) . '/tabnine.log'
  let l:cmd = [
        \   l:tabnine_path,
        \   '--client',
        \   'vim-easycomplete',
        \   '--log-file-path',
        \   l:log_file,
        \ ]

  let s:tn_job = easycomplete#job#start(l:cmd,
        \ {'on_stdout': function('s:StdOutCallback')})
  if s:tn_job <= 0
    call s:log("[TabNine Error]:", "TabNine job start failed")
  else
    let s:tn_ready = v:true
  endif
endfunction

function! s:StdOutCallback(job_id, data, event)
  if a:event != 'stdout'
    return
  endif
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
