" Installer for every lsp server

let s:installer_dir = expand('<sfile>:h:h') . '/easycomplete/installer'
let s:root_dir = expand('<sfile>:h:h')
let s:data_dir = expand('~/.config/vim-easycomplete')
let s:lsp_servers_dir = s:data_dir . '/servers'

function! easycomplete#installer#InstallerDir() abort
  return s:installer_dir
endfunction

function! easycomplete#installer#LspServerDir() abort
  return s:lsp_servers_dir
endfunction

function! easycomplete#installer#install(name) abort

  let opt = easycomplete#GetOptions(a:name)
  let install_script = easycomplete#installer#InstallerDir() . '/' . a:name . '.sh'

  call s:log(install_script)
  if !filereadable(install_script)
    echom '安装文件不存在'
    return
  endif

  return
  " if !empty(a:command) && !lsp_settings#utils#valid_name(a:command)
  "   call lsp_settings#utils#error('Invalid server name')
  "   return
  " endif
  " let l:entry = s:vim_lsp_installer(a:ft, a:command)
  " if empty(l:entry)
  "   call lsp_settings#utils#error('Server not found')
  "   return
  " endif
  " if len(l:entry) < 2
  "   call lsp_settings#utils#error('Server could not be installed. See :messages for details.')
  "   return
  " endif
  " if empty(a:bang) && confirm(printf('Install %s ?', l:entry[0]), "&Yes\n&Cancel") !=# 1
  "   return
  " endif
  " let l:server_install_dir = lsp_settings#servers_dir() . '/' . l:entry[0]
  " if isdirectory(l:server_install_dir)
  "   call lsp_settings#utils#msg('Uninstalling ' . l:entry[0])
  "   call delete(l:server_install_dir, 'rf')
  " endif
  " call mkdir(l:server_install_dir, 'p')
  " call lsp_settings#utils#msg('Installing ' . l:entry[0])
  " if has('nvim')
  "   split new
  "   call termopen(l:entry[1], {'cwd': l:server_install_dir, 'on_exit': function('s:vim_lsp_install_server_post', [l:entry[0]])}) | startinsert
  " else
  "   let l:bufnr = term_start(l:entry[1], {'cwd': l:server_install_dir})
  "   let l:job = term_getjob(l:bufnr)
  "   if l:job != v:null
  "     call job_setoptions(l:job, {'exit_cb': function('s:vim_lsp_install_server_post', [l:entry[0]])})
  "   endif
  " endif
endfunction

function! s:log(msg)
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
