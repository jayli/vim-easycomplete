if get(g:, 'easycomplete_sources_deno')
  finish
endif
let g:easycomplete_sources_deno = 1
let s:file_extensions = ["js","jsx","ts","tsx","mjs","ejs"]

function! easycomplete#sources#deno#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
        \ 'name': 'deno',
        \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name']), 'lsp']},
        \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
        \ 'initialization_options' : {
        \   'enable': v:true,
        \   'lint': v:true,
        \   'unstable': v:true,
        \   'importMap': v:null,
        \   'codeLens': {
        \     'implementations': v:true,
        \     'references': v:true,
        \     'referencesAllFunctions': v:true,
        \     'test': v:true,
        \     'testArgs': ['--allow-all'],
        \   },
        \   "suggest": {
        \     "autoImports": v:true,
        \     "completeFunctionCalls": v:true,
        \     "names": v:true,
        \     "paths": v:true,
        \     "imports": {
        \       "autoDiscover": v:false,
        \       "hosts": {
        \         "https://deno.land/": v:true,
        \       },
        \     },
        \   },
        \   'config': v:null,
        \   'internalDebug': v:false,
        \  },
        \ 'config': {'refresh_pattern': '\(\$[a-zA-Z0-9_:]*\|\k\+\)$'},
        \ 'allowlist': a:opt["whitelist"],
        \ 'blocklist' : [],
        \ 'workspace_config' : {},
        \ 'semantic_highlight' : {},
        \ })
  if easycomplete#sources#deno#IsDenoProject()
    call easycomplete#UnRegisterSource("ts")
  else
    call easycomplete#UnRegisterSource("deno")
  endif
endfunction

function! easycomplete#sources#deno#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#deno#GotoDefinition(...)
  return easycomplete#DoLspDefinition(s:file_extensions)
endfunction

function! easycomplete#sources#deno#filter(matches)
  let ctx = easycomplete#context()
  let matches = a:matches
  let matches = map(copy(matches), function("easycomplete#util#FunctionSurffixMap"))
  return matches
endfunction

function! easycomplete#sources#deno#IsTSOrJSFiletype()
  if index(s:file_extensions, easycomplete#util#extention()) >= 0
    return v:true
  else
    return v:false
  endif
endfunction

function! easycomplete#sources#deno#IsDenoProject()
  if !easycomplete#sources#deno#IsTSOrJSFiletype() | return v:false | endif
  let current_file_path = easycomplete#util#GetCurrentFullName()
  let current_file_dir = fnamemodify(expand('%'), ':p:h')
  let ts_project_patterns = ["package.json", "tsconfig.json"]
  let deno_project_patterns = ["deno.json", "deno.jsonc", "import_map.json"]
  " 当存在 node_modules 时的情况要排除
  if isdirectory(current_file_dir . "/node_modules")
    return v:false
  endif
  for package_file in ts_project_patterns + deno_project_patterns
    let project_package_file = easycomplete#util#FindNearestParentFile(current_file_path, package_file)
    if !empty(project_package_file) && s:HasNodeMudulesDir(project_package_file)
      return v:false
    endif
  endfor
  " 存在 deno 配置文件
  for package_file in deno_project_patterns
    let project_package_file = easycomplete#util#FindNearestParentFile(current_file_path, package_file)
    if !empty(project_package_file)
      return v:true
    endif
  endfor
  return v:false
  " TODO 根据文件内容是否有 import http 来判断是否是 deno 文件
endfunction

function! s:HasNodeMudulesDir(package_file)
  if empty(a:package_file) | return v:false | endif
  let project_root = fnamemodify(a:package_file, ':p:h')
  if isdirectory(project_root . "/node_modules")
    return v:true
  else
    return v:false
  endif
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
