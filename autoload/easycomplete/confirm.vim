let s:win_borderchars = ['─', '│', '─', '│', '┌', '┐', '┘', '└']
function! easycomplete#confirm#pop(title, cb) abort
  if s:is_vim && exists('*popup_dialog')
    try
      call popup_dialog(a:title. ' (y/n)?', {
        \ 'highlight': 'Normal',
        \ 'filter': 'popup_filter_yesno',
        \ 'callback': {id, res -> a:cb(v:null, res)},
        \ 'borderchars': s:win_borderchars,
        \ 'borderhighlight': ['Pmenu']
        \ })
    catch /.*/
      call a:cb(v:exception)
    endtry
    return
  endif
  if has('nvim-0.4.0')
    let text = ' '. a:title . ' (y/n)? '
    let width = min([&columns - 4, strdisplaywidth(text)])
    let height = 3
    let top = ((&lines - height) / 2) - 1
    let left = (&columns - width) / 2
    let opts = {
      \ 'relative': 'editor',
      \ 'row': top,
      \ 'col': left,
      \ 'width': width,
      \ 'height': height,
      \ 'style': 'minimal',
      \ 'focusable': v:false
      \ }

    let top = "┌" . repeat("─", width - 2) . "┐"
    let mid = "│" . repeat(" ", width - 2) . "│"
    let bot = "└" . repeat("─", width - 2) . "┘"

    let lines = [top] + repeat([mid], height - 2) + [bot]
    let border_bufnr = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(border_bufnr, 0, -1, v:true, lines)
    let s:border_winid = nvim_open_win(border_bufnr, v:true, opts)
    let opts.row += 1
    let opts.height -= 2
    let opts.col += 2
    let opts.width -= 4
    let opts.focusable = v:true
    let text_bufnr = nvim_create_buf(v:false, v:true)
    let text_winid = nvim_open_win(text_bufnr, v:true, opts)
    let winhl = "'Normal:Pmenu"
    call setwinvar(s:border_winid, '&winhl', winhl)
    call setwinvar(text_winid, '&winhl', winhl)
    call setwinvar(s:border_winid, '&list', 0)
    call setwinvar(s:border_winid, '&number', 0)
    call setwinvar(s:border_winid, '&relativenumber', 0)
    call setwinvar(s:border_winid, '&cursorcolumn', 0)
    call setwinvar(s:border_winid, '&colorcolumn', 0)
    call setwinvar(s:border_winid, '&wrap', 1)
    au WinClosed * ++once :q | call nvim_win_close(s:border_winid, v:true)

    while 1
      let key = nr2char(getchar())
      if key == "\<C-c>"
        let res = -1
        break
      elseif key == "\<esc>" || key == 'n' || key == 'N'
        let res = 0
        break
      elseif key == 'y' || key == 'Y' || key == "\<CR>"
        let res = 1
        break
      endif
    endw
    call s:close(winid)
    call a:cb(v:null, res)
  elseif exists('*confirm')
    let choice = confirm(a:title, "&Yes\n&No")
    call a:cb(v:null, choice == 1)
  else
    echohl MoreMsg
    echom a:title.' (y/n)'
    echohl None
    let confirm = nr2char(getchar())
    redraw!
    if !(confirm ==? "y" || confirm ==? "\r")
      echohl Moremsg | echo 'Cancelled.' | echohl None
      return 0
      call a:cb(v:null, 0)
    end
    call a:cb(v:null, 1)
  endif
endfunction

" for nvim only
function! s:close(winid)
  call easycomplete#util#execute(winid, ["silent noa call feedkeys('ZZ')"])
endfunction

