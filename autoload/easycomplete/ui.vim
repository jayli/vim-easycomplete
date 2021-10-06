" 菜单样式设置
" 支持四种 dark, light, rider, sharp
function! easycomplete#ui#SetScheme()
  if !exists("g:easycomplete_scheme")
    return
  endif

  " hi Pmenu      ctermfg=111 ctermbg=235
  " hi PmenuSel   ctermfg=255 ctermbg=238
  " hi PmenuSbar              ctermbg=235
  " hi PmenuThumb             ctermbg=234
  let l:scheme_config = {
        \   'light':[[234, 251],[255, 26],[-1,  251],[-1,  247]],
        \   'rider':[[251, 237],[231, 25],[-1,  237],[-1,  239]],
        \   'sharp':[[255, 237],[235, 255],[-1, 245],[-1,  255]],
        \   'blue': [['White', 'DarkBlue'],['Red', 'White'],[-1, 245],[-1,  255]]
        \ }
  if has_key(l:scheme_config, g:easycomplete_scheme)
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
endfunction

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
  if has("gui_running")
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
  return 'none'
endfunction " }}}

" Hilight {{{
function! easycomplete#ui#HighlightArgs(name)
  return 'hi ' . substitute(split(execute('hi ' . a:name), '\n')[0], '\<xxx\>', '', '')
endfunction "}}}

" Set color {{{
function! easycomplete#ui#hi(group, fg, bg, attr)
  let prefix = has("gui_running") ? "gui" : "cterm"
  if !empty(a:fg) && a:fg != -1
    call execute(join(['hi', a:group, prefix . "fg=" . a:fg ], " "))
  endif
  if !empty(a:bg) && a:bg != -1
    call execute(join(['hi', a:group, prefix . "bg=" . a:bg ], " "))
  endif
  if !empty(a:attr) && a:attr != ""
    call execute(join(['hi', a:group, prefix . "=" . a:attr ], " "))
  endif
endfunction " }}}
