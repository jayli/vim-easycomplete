
function! easycomplete#util#filetype()
  " SourcePost 事件中 &filetype 为空，应当从 bufname 中根据后缀获取
  " TODO 这个函数需要重写
  let filename = fnameescape(fnamemodify(bufname('%'),':p'))
  let ext_part = substitute(filename,"^.\\+[\\.]","","g")
  let filetype_dict = {
        \ 'js':'javascript',
        \ 'ts':'typescript',
        \ 'jsx':'javascript.jsx',
        \ 'tsx':'javascript.jsx',
        \ 'py':'python',
        \ 'rb':'ruby',
        \ 'sh':'shell'
        \ }
  if index(['js','ts','jsx','tsx','py','rb','sh'], ext_part) >= 0
    return filetype_dict[ext_part]
  else
    return ext_part
  endif
endfunction

" 运行一个全局的 Timer，只在 complete 的时候用
" 参数：method, args, timer
" method 必须是一个全局方法,
" timer 为空则默认为0
function! easycomplete#util#AsyncRun(...)
  let Method = a:1
  let args = exists('a:2') ? a:2 : []
  let delay = exists('a:3') ? a:3 : 0
  let g:easycomplete_popup_timer = timer_start(delay, { -> easycomplete#util#call(Method, args)})
  return g:easycomplete_popup_timer
endfunction

function! easycomplete#util#StopAsyncRun()
  if exists('g:easycomplete_popup_timer') && g:easycomplete_popup_timer > 0
    call timer_stop(g:easycomplete_popup_timer)
  endif
endfunction

function! easycomplete#util#call(method, args) abort
  try
    if type(a:method) == 2 " 是函数
      let TmpCallback = function(a:method, a:args)
      call TmpCallback()
    endif
    if type(a:method) == type("string") " 是字符串
      call call(a:method, a:args)
    endif
    let g:easycomplete_popup_timer = -1
    redraw
  catch /.*/
    return 0
  endtry
endfunction

function! easycomplete#util#FuzzySearch(needle, haystack)
  let tlen = strlen(a:haystack)
  let qlen = strlen(a:needle)
  if qlen > tlen
    return v:false
  endif
  if qlen == tlen
    return a:needle ==? a:haystack ? v:true : v:false
  endif

  let needle_ls = str2list(tolower(a:needle))
  let haystack_ls = str2list(tolower(a:haystack))

  let i = 0
  let j = 0
  let fallback = 0
  while i < qlen
    let nch = needle_ls[i]
    let i += 1
    let fallback = 0
    while j < tlen
      if haystack_ls[j] == nch
        let j += 1
        let fallback = 1
        break
      else
        let j += 1
      endif
    endwhile
    if fallback == 1
      continue
    endif
    return v:false
  endwhile
  return v:true
endfunction

function! easycomplete#util#NotInsertMode()
  return mode()[0] != 'i' ? v:true : v:false
endfunction

function! easycomplete#util#Sendkeys(keys)
  call feedkeys( a:keys, 'in' )
endfunction

function! easycomplete#util#GetTypingWord()
  let start = col('.') - 1
  let line = getline('.')
  let width = 0
  while start > 0 && line[start - 1] =~ '[a-zA-Z0-9_#]'
    let start = start - 1
    let width = width + 1
  endwhile
  let word = strpart(line, start, width)
  return word
endfunction

function! s:log(msg)
  call easycomplete#log(a:msg)
endfunction
