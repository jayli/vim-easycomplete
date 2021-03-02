
let s:is_win = has('win32') || has('win64')
let s:autotok = 'AUTO332'

function! easycomplete#sources#flow#completor(opt, ctx) abort
  let l:file = a:ctx['filepath']
  if empty(l:file)
    return
  endif

  let l:tempfile = s:write_buffer_to_tempfile(a:ctx)

  let l:config = get(a:opt, 'config', {})
  let l:flowbin_path = get(l:config, 'flowbin_path', 'flow')

  let l:cmd = ['sh', '-c', 'cd "' . expand('%:p:h') . '" && ' . l:flowbin_path . ' autocomplete --json "' . l:file . '" < "' . l:tempfile . '"']

  let l:params = { 'stdout_buffer': '', 'file': l:tempfile }

  let l:jobid = easycomplete#job#start(l:cmd, {
        \ 'on_stdout': function('s:handler', [a:opt, a:ctx, l:params]),
        \ 'on_stderr': function('s:handler', [a:opt, a:ctx, l:params]),
        \ 'on_exit': function('s:handler', [a:opt, a:ctx, l:params]),
        \ })

  call easycomplete#log(l:cmd)

  if l:jobid <= 0
    call delete(l:tempfile)
  endif
endfunction

function! s:handler(opt, ctx, params, id, data, event) abort
  if a:event ==? 'stdout'
    let a:params['stdout_buffer'] = a:params['stdout_buffer'] . join(a:data, "\n")
  elseif a:event ==? 'exit'
    if a:data == 0
      let l:res = json_decode(a:params['stdout_buffer'])
      call easycomplete#log(l:res)
      if !empty(l:res) && !empty(l:res['result'])

        let l:config = get(a:opt, 'config', {})
        if get(l:config, 'show_typeinfo', 0)
          let l:mapper = '{"word": v:val["name"], "dup": 1, "icase": 1, "menu": "[Flow]    " . v:val["type"]}'
        else
          let l:mapper = '{"word": v:val["name"], "dup": 1, "icase": 1, "menu": "[Flow]"}'
        endif

        let l:matches = map(l:res['result'], l:mapper)

        let l:col = a:ctx['col']
        let l:typed = a:ctx['typed']
        let l:kw = matchstr(l:typed, '\w\+$')
        let l:kwlen = len(l:kw)
        let l:startcol = l:col - l:kwlen

        call easycomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
      endif
    endif
    call delete(a:params['file'])
  elseif a:event ==? 'stdout'
    call easycomplete#log(a:data)
  endif
endfunction

function! easycomplete#sources#flow#get_source_options(opts)
  return extend(extend({}, a:opts), {
        \ 'refresh_pattern': '\(\k\+$\|\.$\)',
        \ })
endfunction

let s:cached_flowbin_path_by_dir = {} " dir: <path to flow>

function! s:write_buffer_to_tempfile(ctx) abort
  let l:lines = getline(1, '$')
  let l:lnum = a:ctx['lnum']
  let l:col = a:ctx['col']

  " Insert the base and magic token into the current line.
  let l:curline = l:lines[l:lnum - 1]
  let l:lines[l:lnum - 1] = l:curline[:l:col - 1] . s:autotok . l:curline[l:col:]

  let l:file = tempname()
  call writefile(l:lines, l:file)
  return l:file
endfunction
