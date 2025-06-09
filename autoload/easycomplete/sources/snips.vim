
function! easycomplete#sources#snips#completor(opt, ctx)
  if !easycomplete#SnipSupports()
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  let l:typing = a:ctx['typing']
  if index(['.','/',':'], a:ctx['char']) >= 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  if strlen(l:typing) == 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  call timer_start(10, {
        \ -> easycomplete#sources#snips#CompleteHandler(l:typing, a:opt['name'], a:ctx, a:ctx['startcol'])
        \ })
  " #133
  " call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  return v:true
endfunction

function! easycomplete#sources#snips#CompleteHandler(typing, name, ctx, startcol)
  let suggestions = []
  " 0.010s for these two function call
  let snippets = UltiSnips#SnippetsInCurrentScope()
  call UltiSnips#SnippetsInCurrentScope(1)

  for trigger in keys(snippets)
    try
      let description = get(snippets, trigger, "")
      let description = empty(description) ? "Snippet: " . trigger : description
      let snip_object = s:GetSnipObject(trigger, g:current_ulti_dict_info)
    catch /^Vim\%((\a\+)\)\=:E684/
      " trigger 有可能是 i|n 这类包含特殊字符情况
      continue
    endtry
    try
      " Vim 性能比 Python 快五倍
      let code_info = easycomplete#util#GetSnippetsCodeInfo(snip_object)
    catch
      if has("python3")
        let code_info = easycomplete#python#GetSnippetsCodeInfo(snip_object)
      else
        continue
      endif
    endtry
    let sha256_str = strpart(easycomplete#util#Sha256(trigger . string(code_info)), 0, 15)
    let user_data_json = {
          \     'plugin_name': a:name,
          \     'sha256': sha256_str,
          \   }
    call add(suggestions, {
          \ 'word' : trigger,
          \ 'abbr' : trigger . '~',
          \ 'kind' : g:easycomplete_kindflag_snip,
          \ 'menu' : g:easycomplete_menuflag_snip,
          \ 'user_data': json_encode(user_data_json),
          \ 'info' : [description, "-----"] + s:CodeInfoFilter(code_info),
          \ 'user_data_json': user_data_json
          \ })
  endfor
  call easycomplete#complete(a:name, a:ctx, a:startcol, suggestions)
endfunction

function! s:CodeInfoFilter(code_info)
  let code_info = type(a:code_info) == type("") ? [a:code_info] : a:code_info
  let count_index = 0
  let result_info = []
  while count_index < len(code_info)
    let tmp_code_snip = code_info[count_index]
    let tmp_code_snip = substitute(tmp_code_snip, "$\\d\\+","","g")
    let tmp_code_snip = substitute(tmp_code_snip, "${\\d\\+:\\(\[^}\]\\+\\)}",'\=submatch(1)',"g")
    let tmp_code_snip = substitute(tmp_code_snip, "${\\d\\+}",'',"g")
    let tmp_code_snip = substitute(tmp_code_snip, "${\\(\[^}\]\\+\\)}"," ","g")
    call add(result_info, tmp_code_snip)
    let count_index += 1
  endwhile
  return result_info
endfunction

function! s:GetSnipObject(trigger, current_ulti_dict_info)
  let info_str = get(a:current_ulti_dict_info, a:trigger)['location']
  let info_str_array = split(info_str, ":")
  let snip_object = {}
  let snip_object.filepath = info_str_array[0]
  let snip_object.line_number = info_str_array[1]
  return snip_object
endfunction

function! easycomplete#sources#snips#constructor(...)
  " Do Nothing
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:once(...)
  return call('easycomplete#util#once', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
