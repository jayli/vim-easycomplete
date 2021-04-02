if get(g:, 'easycomplete_sources_py')
  finish
endif
let g:easycomplete_sources_py = 1

function! easycomplete#sources#py#constructor(opt, ctx)
  " 注册 lsp
  if executable('pyls')
    " pip install python-language-server
    call easycomplete#lsp#register_server({
          \ 'name': 'pyls',
          \ 'cmd': {server_info->['pyls']},
          \ 'allowlist': ['python'],
          \ })
  endif
  " if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
endfunction

function! easycomplete#sources#py#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#py#GotoDefinition(...)
  return v:false
  let ext = tolower(easycomplete#util#extention())
  if index(["py"], ext) >= 0
    let l:ctx = easycomplete#context()
    call lsp#tagfunc(expand('<cword>'), mode(), l:ctx['filepath'])
    " call s:GotoDefinition(l:ctx["filepath"], l:ctx["lnum"], l:ctx["col"])
    " return v:true 成功跳转，告知主进程
    return v:true
  endif
  " exec "tag ". expand('<cword>')
  " 未成功跳转，则交给主进程处理
  return v:false
endfunction


function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
  " nmap <buffer> gd <plug>(lsp-definition)
  " nmap <buffer> gs <plug>(lsp-document-symbol-search)
  " nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
  " nmap <buffer> gr <plug>(lsp-references)
  " nmap <buffer> gi <plug>(lsp-implementation)
  " nmap <buffer> gt <plug>(lsp-type-definition)
  " nmap <buffer> <leader>rn <plug>(lsp-rename)
  " nmap <buffer> [g <plug>(lsp-previous-diagnostic)
  " nmap <buffer> ]g <plug>(lsp-next-diagnostic)
  " nmap <buffer> K <plug>(lsp-hover)
  " inoremap <buffer> <expr><c-f> lsp#scroll(+4)
  " inoremap <buffer> <expr><c-d> lsp#scroll(-4)

  let g:lsp_format_sync_timeout = 1000
  " autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

  " refer to doc to add more commands
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
