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

function! easycomplete#installer#GetCommand(name)
  let opt = easycomplete#GetOptions(a:name)
  if empty(opt)
    echom 'error'
    return ''
  endif
  let cmd = opt['command']
  if executable(cmd)
    return cmd
  endif
  let local_cmd = easycomplete#installer#LspServerDir() . '/' . a:name . '/' . cmd
  if executable(local_cmd)
    return local_cmd
  endif
  return ''
endfunction

function! easycomplete#installer#install(name) abort

  let opt = easycomplete#GetOptions(a:name)
  let l:install_script = easycomplete#installer#InstallerDir() . '/' . a:name . '.sh'
  let l:lsp_server_dir = easycomplete#installer#LspServerDir() . '/' . a:name

  call s:log(l:install_script)
  if !filereadable(l:install_script)
    echom '安装文件不存在'
    return
  endif

  if confirm(printf('Install %s lsp server?', a:name), "&Yes\n&Cancel") !=# 1
    return
  endif

  if isdirectory(l:lsp_server_dir)
    echom 'Uninstalling ' . a:name
    call delete(l:lsp_server_dir, 'rf')
  endif

  call mkdir(l:lsp_server_dir, 'p')
  echom 'Installing ' . a:name . '...'

  call setfperm(l:install_script, 'rwxr-xr-x')
  call setfperm(easycomplete#installer#InstallerDir() . '/npm_install.sh', 'rwxr-xr-x')

  if has('nvim')
    split new
    call termopen(l:install_script, {'cwd': l:lsp_server_dir, 'on_exit': function('s:InstallServerPost', [a:name])})
    startinsert
  else
    let l:bufnr = term_start(l:install_script, {'cwd': l:lsp_server_dir})
    let l:job = term_getjob(l:bufnr)
    if l:job != v:null
      call job_setoptions(l:job, {'exit_cb': function('s:InstallServerPost', [a:name])})
    endif
  endif
endfunction

" neovim passes third argument as 'exit' while vim passes only 2 arguments
function! s:InstallServerPost(command, job, code, ...) abort
  if a:code != 0
    return
  endif
  if s:executable(a:command)
    call easycomplete#Enable()
  endif
  echom 'Installed ' . a:command
endfunction

function! s:executable(cmd) abort
  if executable(a:cmd)
    return 1
  endif
  let plug_name = easycomplete#GetPlugNameByCommand(a:cmd)
  if empty(plug_name) | return 0 | endif
  let local_cmd = easycomplete#installer#LspServerDir() . '/' . plug_name . '/' . a:cmd
  if !filereadable(local_cmd) | return 0 | endif
  if executable(local_cmd)
    return 1
  endif
  return 0
endfunction

function! easycomplete#installer#executable(...)
  return call("s:executable", a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
