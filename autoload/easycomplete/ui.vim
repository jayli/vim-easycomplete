" Cterm 下默认四种菜单样式
" 支持四种 dark, light, rider, sharp
" Set Scheme {{{
function! easycomplete#ui#SetScheme()
  if !exists("g:easycomplete_scheme")
    return
  endif
  " hi Pmenu      ctermfg=111 ctermbg=235
  " hi PmenuSel   ctermfg=255 ctermbg=238
  " hi PmenuSbar              ctermbg=235
  " hi PmenuThumb             ctermbg=234
  let l:scheme_config = {
        \   'light': [[234, 251], [255, 26], [-1,  251], [-1,  247]],
        \   'rider': [[251, 237], [231, 25], [-1,  237], [-1,  239]],
        \   'sharp': [[255, 237], [235, 255], [-1, 245], [-1,  255]],
        \   'blue':  [['White', 'DarkBlue'], ['Red', 'White'], [-1, 245],[-1,  255]],
        \ }
  if has_key(l:scheme_config, g:easycomplete_scheme) && g:env_is_iterm == v:false
    let sch = l:scheme_config[g:easycomplete_scheme]
    let hiPmenu =      ['hi','Pmenu',      'ctermfg='.sch[0][0], 'ctermbg='.sch[0][1]]
    let hiPmenuSel =   ['hi','PmenuSel',   'ctermfg='.sch[1][0], 'ctermbg='.sch[1][1]]
    let hiPmenuSbar =  ['hi','PmenuSbar',  '',                   'ctermbg='.sch[2][1]]
    let hiPmenuThumb = ['hi','PmenuThumb', '',                   'ctermbg='.sch[3][1]]
    execute join(hiPmenu, ' ')
    execute join(hiPmenuSel, ' ')
    execute join(hiPmenuSbar, ' ')
    execute join(hiPmenuThumb, ' ')
  endif

  if g:env_is_iterm == v:true
    if g:easycomplete_scheme == 'sharp'
      hi! PMenu guifg=#d4d4d4 guibg=#252526 gui=NONE
      hi! PmenuSel guifg=#ffffff guibg=#04395e gui=NONE
      hi! PmenuSbar guibg=#252526
      hi! PmenuThumb guibg=#474747
    endif

  endif
endfunction " }}}

" markdown syntax {{{
function! easycomplete#ui#ApplyMarkdownSyntax(winid)
  " 默认 Popup 的 Markdown 文档都基于 help syntax
  let regin_cmd = join(["syntax region NewCodeBlock matchgroup=Conceal start=/\%(``\)\@!`/ ",
                \ "matchgroup=Conceal end=/\%(``\)\@!`/ containedin=TOP concealends"],"")
  let original_filetype = getwinvar(a:winid, "&filetype")
  if has("nvim")
    let exec_cmd = [
          \ "hi helpCommand cterm=underline gui=underline ctermfg=White guifg=White",
          \ "silent! syntax clear NewCodeBlock",
          \ regin_cmd,
          \ "hi! link NewCodeBlock helpCommand",
          \ "let &filetype='help'",
          \ ]
  else
    let exec_cmd = [
          \ "hi helpCommand cterm=underline gui=underline ctermfg=White guifg=White",
          \ "silent! syntax clear NewCodeBlock",
          \ regin_cmd,
          \ "hi! link NewCodeBlock helpCommand",
          \ "let &filetype='" . original_filetype . "'",
          \ ]
  endif
  call easycomplete#util#execute(a:winid, exec_cmd)
endfunction " }}}

" Get back ground color form a GroupName {{{
function! easycomplete#ui#GetBgColor(name)
  return easycomplete#ui#GetHiColor(a:name, "bg")
endfunction "}}}

" Get back ground color form a GroupName {{{
function! easycomplete#ui#GetFgColor(name)
  return easycomplete#ui#GetHiColor(a:name, "fg")
endfunction "}}}

" Get color from a scheme group {{{
function! easycomplete#ui#GetHiColor(hiName, sufix)
  let sufix = empty(a:sufix) ? "bg" : a:sufix
  let hlString = easycomplete#ui#HighlightArgs(a:hiName)
  if empty(hlString) | return "NONE" | endif
  if easycomplete#util#IsGui()
    " Gui color name
    let my_color = matchstr(hlString,"\\(\\sgui" . sufix . "=\\)\\@<=#\\w\\+")
    if my_color != ''
      return my_color
    endif
  else
    let my_color= matchstr(hlString,"\\(\\scterm" .sufix. "=\\)\\@<=\\w\\+")
    if my_color!= ''
      return my_color
    endif
  endif
  return 'NONE'
endfunction " }}}

" Hilight {{{
function! easycomplete#ui#HighlightArgs(name)
  try
    let val = 'hi ' . substitute(split(execute('hi ' . a:name), '\n')[0], '\<xxx\>', '', '')
  catch /411/
    return ""
  endtry
  return val
endfunction "}}}

" Set color {{{
function! easycomplete#ui#hi(group, fg, bg, attr)
  let prefix = easycomplete#util#IsGui() ? "gui" : "cterm"
  if !empty(a:fg) && a:fg != -1
    call execute(join(['hi', a:group, prefix . "fg=" . a:fg ], " "))
  endif
  if !empty(a:bg) && a:bg != -1
    call execute(join(['hi', a:group, prefix . "bg=" . a:bg ], " "))
  endif
  if exists("a:attr") && !empty(a:attr) && a:attr != ""
    call execute(join(['hi', a:group, prefix . "=" . a:attr ], " "))
  endif
endfunction " }}}

" ClearSyntax {{{
function! easycomplete#ui#ClearSyntax(group)
  try
    execute printf('silent! syntax clear %s', a:group)
  catch /.*/
  endtry
endfunction " }}}

function! easycomplete#ui#qfhl() " {{{
  if easycomplete#ui#GetHiColor("qfLineNr", "fg") == 'NONE'
    hi qfLineNr ctermfg=LightBlue guifg=#6d96bf
  endif
endfunction " }}}

function! easycomplete#ui#HighlightWordUnderCursor() " {{{
  if empty(g:easycomplete_cursor_word_hl) | return | endif
  let disabled_ft = ["help", "qf", "fugitive", "nerdtree", "gundo", "diff", "fzf", "floaterm"]
  if &diff || &buftype == "terminal" || index(disabled_ft, &filetype) >= 0
    return
  endif
  if getline(".")[col(".")-1] !~# '[[:punct:][:blank:]]'
    let bgcolor = easycomplete#ui#GetBgColor("Search")
    let prefix_key = easycomplete#util#IsGui() ? "guibg" : "ctermbg"
    let append_str = s:IsSearchWord() ? join([prefix_key, bgcolor], "=") : join([prefix_key, "NONE"], "=")
    exec "hi MatchWord cterm=underline gui=underline " . append_str
    try
      exec '2match' 'MatchWord' '/\V\<'.expand('<cword>').'\>/'
    catch
      " do nothing
    endtry
  else
    2match none
  endif
endfunction

function! s:IsSearchWord()
  let current_word = expand('<cword>')
  let search_word = histget("search")
  let search_word = substitute(search_word, "^\\\\\<", "", "g")
  let search_word = substitute(search_word, "\\\\\>$", "", "g")
  if &ignorecase
    return current_word == search_word
  else
    return current_word ==# search_word
  endif
endfunction " }}}

" console {{{
function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction " }}}

" log {{{
function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction " }}}

" get {{{
function! s:get(...)
  return call('easycomplete#util#get', a:000)
endfunction " }}}
