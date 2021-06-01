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
        \   'dark':[[15, 237],[235, 190],[-1,  235],[-1,  234]],
        \   'light':[[234, 251],[255, 26],[-1,  251],[-1,  247]],
        \   'rider':[[251, 237],[231, 25],[-1,  237],[-1,  239]],
        \   'sharp':[[255, 237],[235, 255],[-1, 245],[-1,  255]]
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
