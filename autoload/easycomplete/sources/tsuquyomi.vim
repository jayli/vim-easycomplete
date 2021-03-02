if get(g:, 'loaded_autoload_easycomplete_sources_tsuquyomi')
  finish
endif
let g:loaded_autoload_easycomplete_sources_tsuquyomi = 1
let s:save_cpo = &cpo
set cpo&vim

" Copied from https://github.com/yami-beta/easycomplete-omni.vim
" ORIGINAL LICENCE: MIT
" ORIGINAL AUTHOR: Takahiro Abe
function! easycomplete#sources#tsuquyomi#get_source_options(opts) abort
  return extend({
        \ 'refresh_pattern': '\%(\k\|\.\)',
        \}, a:opts)
endfunction

" Forked from https://github.com/yami-beta/easycomplete-omni.vim
" ORIGINAL LICENCE: MIT
" ORIGINAL AUTHOR: Takahiro Abe
" MODIFIED BY: ishitaku5522
function! easycomplete#sources#tsuquyomi#completor(opt, ctx) abort
  try
    let l:col = a:ctx['col']
    let l:typed = a:ctx['typed']

    let l:startcol = s:safe_tsuquyomifunc(1, '')
    if l:startcol < 0
      return
    elseif l:startcol > l:col
      let l:startcol = l:col
    endif
    let l:base = l:typed[l:startcol : l:col]
    let l:matches = s:safe_tsuquyomifunc(0, l:base)
    call easycomplete#log(l:matches)

    " call easycomplete#complete(a:opt['name'], a:ctx, l:startcol + 1, l:matches)
  catch
    call easycomplete#log('tsuquyomi error ' . v:exception)
  endtry
endfunction

" Copied from https://github.com/Quramy/tsuquyomi
" ORIGINAL LICENCE: MIT
" ORIGINAL FILE: autoload/tsuquyomi.vim
" ORIGINAL AUTHOR: Quramy <yosuke.kurami@gmail.com>
function! s:flush()
  if tsuquyomi#bufManager#isDirty(expand('%:p'))
    let file_name = expand('%:p')
    call tsuquyomi#bufManager#saveTmp(file_name)
    call tsuquyomi#tsClient#tsReload(file_name, tsuquyomi#bufManager#tmpfile(file_name))
    call tsuquyomi#bufManager#setDirty(file_name, 0)
  endif
endfunction

" Copied from https://github.com/Quramy/tsuquyomi
" ORIGINAL LICENCE: MIT
" ORIGINAL FILE: autoload/tsuquyomi.vim
" ORIGINAL AUTHOR: Quramy <yosuke.kurami@gmail.com>
function! s:checkOpenAndMessage(filelist)
  if tsuquyomi#tsClient#statusTss() == 'dead'
    return [[], a:filelist]
  endif
  let opened = []
  let not_opend = []
  for file in a:filelist
    if tsuquyomi#bufManager#isOpened(file)
      call add(opened, file)
    else
      call add(not_opend, file)
    endif
  endfor
  if len(not_opend)
    for file in not_opend
      if tsuquyomi#bufManager#isNotOpenable(file)
        echom '[Tsuquyomi] The buffer "'.file.'" is not valid filepath, so tusuqoymi cannot open this buffer.'
        return [opened, not_opend]
      endif
    endfor
    echom '[Tsuquyomi] Buffers ['.join(not_opend, ', ').'] are not opened by TSServer. Please exec command ":TsuquyomiOpen '.join(not_opend).'" and retry.'
  endif
  return [opened, not_opend]
endfunction

" Copied from https://github.com/Quramy/tsuquyomi
" ORIGINAL LICENCE: MIT
" ORIGINAL FILE: autoload/tsuquyomi.vim
" ORIGINAL AUTHOR: Quramy <yosuke.kurami@gmail.com>
function! s:sortTextComparator(entry1, entry2)
  if a:entry1.sortText < a:entry2.sortText
    return -1
  elseif a:entry1.sortText > a:entry2.sortText
    return 1
  else
    return 0
  endif
endfunction

function! s:complete_add(item) abort
  let a:item['menu'] = '[tsuquyomi]'
  call add(s:candidates, a:item)
endfunction

" Forked from https://github.com/Quramy/tsuquyomi
" ORIGINAL LICENCE: MIT
" ORIGINAL FILE: autoload/tsuquyomi.vim
" ORIGINAL AUTHOR: Quramy <yosuke.kurami@gmail.com>
" MODIFIED BY: ishitaku5522
function! s:safe_tsuquyomifunc(findstart, base)
  if len(s:checkOpenAndMessage([expand('%:p')])[1])
    return
  endif

  let s:candidates = []

  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')

  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if(a:findstart)
    call tsuquyomi#perfLogger#record('before_flush')
    call s:flush()
    call tsuquyomi#perfLogger#record('after_flush')
    return l:start - 1
  else
    let l:file = expand('%:p')
    let l:res_dict = {'words': []}
    call tsuquyomi#perfLogger#record('before_tsCompletions')
    " By default the result list will be sorted by the 'name' properly alphabetically
    let l:alpha_sorted_res_list = tsuquyomi#tsClient#tsCompletions(l:file, l:line, l:start, a:base)
    call tsuquyomi#perfLogger#record('after_tsCompletions')

    let is_javascript = (&filetype == 'javascript') || (&filetype == 'jsx') || (&filetype == 'javascript.jsx')
    if is_javascript
      " Sort the result list according to how TypeScript suggests entries to be sorted
      let l:res_list = sort(copy(l:alpha_sorted_res_list), 's:sortTextComparator')
    else
      let l:res_list = l:alpha_sorted_res_list
    endif

    let enable_menu = stridx(&completeopt, 'menu') != -1
    let length = strlen(a:base)
    if enable_menu
      call tsuquyomi#perfLogger#record('start_menu')
      if g:tsuquyomi_completion_preview
        let [has_info, siginfo] = tsuquyomi#getSignatureHelp(l:file, l:line, l:start)
      else
        let [has_info, siginfo] = [0, '']
      endif

      let size = g:tsuquyomi_completion_chunk_size
      let j = 0
      while j * size < len(l:res_list)
        let entries = []
        let items = []
        let upper = min([(j + 1) * size, len(l:res_list)])
        for i in range(j * size, upper - 1)
          let info = l:res_list[i]
          if !length
                \ || !g:tsuquyomi_completion_case_sensitive && info.name[0:length - 1] == a:base
                \ || g:tsuquyomi_completion_case_sensitive && info.name[0:length - 1] ==# a:base
            let l:item = {'word': info.name, 'kind': info.kind }
            if has_info
              let l:item.info = siginfo
            endif
            if is_javascript && info.kind == 'warning'
              let l:item.kind = '' " Make display cleaner by not showing 'warning' as the type
            endif
            if !g:tsuquyomi_completion_detail
              call s:complete_add(l:item)
            else
              " if file is TypeScript, then always add to entries list to
              " fetch details. Or in the case of JavaScript, avoid adding to
              " entries list if ScriptElementKind is 'warning'. Because those
              " entries are just random identifiers that occur in the file.
              if !is_javascript || info.kind != 'warning'
                call add(entries, info.name)
              endif
              call add(items, l:item)
            endif
          endif
        endfor
        if g:tsuquyomi_completion_detail
          call tsuquyomi#perfLogger#record('before_completeMenu'.j)
          let menus = tsuquyomi#makeCompleteMenu(l:file, l:line, l:start, entries)
          call tsuquyomi#perfLogger#record('after_completeMenu'.j)
          let idx = 0
          for kind in menus
            let items[idx].kind = kind
            let items[idx].info = kind
            call s:complete_add(items[idx])
            let idx = idx + 1
          endfor
          " For JavaScript completion, there are entries whose
          " ScriptElementKind is 'warning'. tsserver won't have any details
          " returned for them, but they still need to be added at the end.
          for i in range(idx, len(items) - 1)
            call s:complete_add(items[i])
          endfor
        endif
        " if complete_check()
        "   break
        " endif
        let j = j + 1
      endwhile
      return s:candidates
    else
      return filter(map(l:res_list, 'v:val.name'), 'stridx(v:val, a:base) == 0')
    endif

  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
