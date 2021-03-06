" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  整合了字典、代码展开和语法补全的提示插件
"
"               更多信息：
"                   <https://github.com/jayli/vim-easycomplete>

" 初始化入口
function! easycomplete#Enable()
  if exists("g:easycomplete_loaded")
    return
  endif
  let g:easycomplete_loaded = 1

  if !exists("g:easycomplete_source")
    let g:easycomplete_source  = {}
  endif
  let g:easycomplete_menucache = {}
  let g:typing_key             = 0
  let g:easycomplete_menuitems = []

  set completeopt-=menu
  set completeopt+=menuone
  set completeopt+=noselect
  set completeopt-=longest
  "set completeopt+=popup
  set updatetime=300
  " set completeopt-=noinsert
  set cpoptions+=B

  " <C-X><C-U><C-N> 函数回调
  let &completefunc = 'easycomplete#completeFunc'
  " let &completefunc = 'tsuquyomi#complete'
  " let &completefunc = 'easycomplete#nill'
  " 插入模式下的回车事件监听
  inoremap <expr> <CR> TypeEnterWithPUM()
  " 插入模式下 Tab 和 Shift-Tab 的监听
  " inoremap <Tab> <C-R>=CleverTab()<CR>
  " inoremap <S-Tab> <C-R>=CleverShiftTab()<CR>
  inoremap <silent> <Plug>EasyCompTabTrigger  <C-R>=easycomplete#CleverTab()<CR>
  inoremap <silent> <Plug>EasyCompShiftTabTrigger  <C-R>=easycomplete#CleverShiftTab()<CR>
  " autocmd TextChangedI * call easycomplete#typing()

  call easycomplete#ui#SetScheme()

  call plugin#init()
  " 全局初始化
  call s:SetupCompleteCache()
  call s:ConstructorCalling()

  " Binding Maping 过滤条件
  if index([
        \   'typescript','javascript',
        \   'javascript.jsx','go',
        \   'python','vim'
        \ ], easycomplete#util#filetype()) >= 0
    call s:BindingTypingCommand()
  endif
endfunction

function! easycomplete#nill() abort
  return v:none " DO NOTHING
endfunction

function! s:CompleteAsync()
  call s:SendKeys("\<C-X>\<C-U>\<C-P>")
endfunction

function! s:BindingTypingCommand()
  let l:key_liststr = 'abcdefghijklmnopqrstuvwxyz'.
                    \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/.'
  let l:cursor = 0
  while l:cursor < strwidth(l:key_liststr)
    let key = l:key_liststr[l:cursor]
    exec 'inoremap <buffer><silent>' . key . ' ' . key . '<C-R>=easycomplete#typing()<CR>'
    let l:cursor = l:cursor + 1
  endwhile
  inoremap <buffer><silent> <BS> <BS><C-R>=easycomplete#backing()<CR>
  "inoremap <buffer><silent> . .<C-R>=easycomplete#typing()<CR>

  " autocmd CursorHoldI * call easycomplete#CursorHoldI()
endfunction

function! s:SetupCompleteCache()
  let g:easycomplete_menucache = {}
  let g:easycomplete_menucache["_#_1"] = 1  " 当前输入单词行号
  let g:easycomplete_menucache["_#_2"] = 1  " 当前输入单词列号
endfunction

function! s:ResetCompleteCache()
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  let start_pos = col('.') - strwidth(s:GetTypingWord())
  if g:easycomplete_menucache["_#_1"] != line('.') || g:easycomplete_menucache["_#_2"] != start_pos
    let g:easycomplete_menucache = {}
  endif
  let g:easycomplete_menucache["_#_1"] = line('.')  " 行号
  let g:easycomplete_menucache["_#_2"] = start_pos  " 列号
endfunction

function! s:AddCompleteCache(word, menulist)
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  let start_pos = col('.') - strwidth(a:word)
  if g:easycomplete_menucache["_#_1"] == line('.') && g:easycomplete_menucache["_#_2"] == start_pos
    let g:easycomplete_menucache[a:word] = a:menulist
  else
    let g:easycomplete_menucache = {}
  endif
  let g:easycomplete_menucache["_#_1"] = line('.')  " 行号
  let g:easycomplete_menucache["_#_2"] = start_pos  " 列号
endfunction

function! easycomplete#backing()
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  call s:ResetCompleteCache()

  call s:StopAsyncRun()
  if has_key(g:easycomplete_menucache, s:GetTypingWord())
    call s:AsyncRun('easycomplete#backingTimerHandler', [], 500)
    " call easycomplete#backingTimerHandler()
  else
    " TODO 回退的逻辑优化
    " " call s:SendKeys("\<C-X>\<C-U>")
    " call s:StopAsyncRun()
    " call s:completeHandler()
  endif
  return ''
endfunction

function! easycomplete#backingTimerHandler()
  if pumvisible()
    return ''
  endif

  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
    return ''
  endif

  call s:CompleteAdd(get(g:easycomplete_menucache, s:GetTypingWord()))
  return ''
endfunction

" copy of asyncomplete
function! easycomplete#context() abort
  let l:ret = {
        \ 'bufnr':bufnr('%'),
        \ 'curpos':getcurpos(),
        \ 'changedtick':b:changedtick
        \ }
  let l:ret['lnum'] = l:ret['curpos'][1]
  let l:ret['col'] = l:ret['curpos'][2]
  let l:ret['filetype'] = &filetype
  let l:ret['filepath'] = expand('%:p')
  let line = getline(l:ret['lnum'])
  let l:ret['typed'] = strpart(line, 0, l:ret['col']-1)
  let l:ret['char'] = strpart(line, l:ret['col']-2, l:ret['col']-1)
  let l:ret['typing'] = s:GetTypingWord()
  let l:ret['startcol'] = l:ret['col'] - strlen(l:ret['typing'])
  return l:ret
endfunction

" copy of asyncomplete
" 格式上方便兼容 asyncomplete 使用
function! easycomplete#complete(name, ctx, startcol, items, ...) abort
  " call s:update_pum()
  let l:ctx = easycomplete#context()
  if a:ctx["lnum"] != l:ctx["lnum"] || a:ctx["col"] != l:ctx["col"]
    if s:CompleteSourceReady(a:name)
      call s:CloseCompletionMenu()
      " call s:SendKeys("\<C-X>\<C-U>")
      call s:CallCompeltorByName(a:name, l:ctx)
    endif
    return
  endif
  call easycomplete#CompleteAdd(a:items)
endfunction

function! s:CallConstructorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  let b:constructor = get(l:opt, "constructor")
  if b:constructor == 0
    return
  endif
  if type(b:constructor) == 2 " 是函数
    call b:constructor(l:opt, a:ctx)
  endif
  if type(b:constructor) == type("string") " 是字符串
    call call(b:constructor, [l:opt, a:ctx])
  endif
endfunction

function! s:CallCompeltorByName(name, ctx)
  let l:opt = get(g:easycomplete_source, a:name)
  if empty(l:opt) || empty(get(l:opt, "completor"))
    return
  endif
  let b:completor = get(l:opt, "completor")
  if type(b:completor) == 2 " 是函数
    call b:completor(l:opt, a:ctx)
  endif
  if type(b:completor) == type("string") " 是字符串
    call call(b:completor, [l:opt, a:ctx])
  endif
endfunction

function! easycomplete#typing()
  if pumvisible()
    return ""
  endif
  call s:doComplete()
  " call s:SendKeys("\<C-X>\<C-U>")
  return ""
endfunction

function! s:doComplete()
  " call s:CloseCompletionMenu()
  " 过滤非法的'.'点匹配
  let l:ctx = easycomplete#context()
  if strlen(l:ctx['typed']) >= 2 && l:ctx['char'] ==# '.'
        \ && l:ctx['typed'][l:ctx['col'] - 3] !~ '^[a-zA-Z0-9]$'
    call s:CloseCompletionMenu()
    return v:none
  endif

  if strlen(l:ctx['typed']) == 1 && l:ctx['char'] ==# '.'
    call s:CloseCompletionMenu()
    return v:none
  endif

  if l:ctx['char'] == '.'
    call s:CompleteInit()
    call s:ResetCompleteCache()
  endif

  call s:StopAsyncRun()
  call s:AsyncRun(function('s:completeHandler'), [], 0)
  return v:none
endfunction

" call easycomplete#register_source(easycomplete#sources#buffer#get_source_options({
"     \ 'name': 'buffer',
"     \ 'allowlist': ['*'],
"     \ 'blocklist': ['go'],
"     \ 'completor': function('easycomplete#sources#buffer#completor'),
"     \ 'config': {
"     \    'max_buffer_size': 5000000,
"     \  },
"     \ }))
function! easycomplete#registerSource(opt)
  if !has_key(a:opt, "name")
    return
  endif
  if !exists("g:easycomplete_source")
    let g:easycomplete_source = {}
  endif
  let g:easycomplete_source[a:opt["name"]] = a:opt
  " call s:CallConstructorByName(a:opt["name"], easycomplete#context())
endfunction

" 依次执行安装完了的每个匹配器，依次调用每个匹配器的 completor 函数
" 每个 completor 函数中再调用 CompleteAdd
function! s:CompletorCalling(...)
  let l:ctx = easycomplete#context()
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item)
      call s:CallCompeltorByName(item, l:ctx)
    endif
  endfor
endfunction

function! s:ConstructorCalling(...)
  let l:ctx = easycomplete#context()
  for item in keys(g:easycomplete_source)
    if s:CompleteSourceReady(item)
      call s:CallConstructorByName(item, l:ctx)
    endif
  endfor
endfunction

function! s:CompleteSourceReady(name)
  if has_key(g:easycomplete_source, a:name)
    let completor_source = get(g:easycomplete_source, a:name)
    if has_key(completor_source, 'whitelist')
      let whitelist = get(completor_source, 'whitelist')
      if index(whitelist, &filetype) >= 0 || index(whitelist, "*") >= 0
        return 1
      else
        return 0
      endif
    else
      return 1
    endif
  else
    return 0
  endif
endfunction

function! s:CompleteRunning()
  if !exists('g:easycomplete_popup_timer') || g:easycomplete_popup_timer == -1
    return 0
  endif

  let l:timer = timer_info(g:easycomplete_popup_timer)
  " try
    return string(l:timer) != "[]"
  " catch /.*/
  "   return 0
  " endtry
endfunction

function! s:StopTSServer()
  if exists('g:easycomplete_tsserver_stopped') && g:easycomplete_tsserver_stopped == 1
    " Do Nothing
  else
    call tsuquyomi#stopServer()
    let g:easycomplete_tsserver_stopped = 1
  endif
endfunction

function! s:StartTSServer()
  if exists('g:easycomplete_tsserver_stopped') && g:easycomplete_tsserver_stopped == 1
    " call tsuquyomi#config#initBuffer({ 'pattern': '*.js,*.jsx,*.ts' })
    let g:easycomplete_tsserver_stopped = 0
  else
    " Do Nothing
  endif
endfunction

function! easycomplete#startTsServer()
  call s:StartTSServer()
endfunction

function! s:GetTypingKey()
  if exists('g:typing_key') && g:typing_key != ""
    return g:typing_key
  endif
  return "\<Tab>"
endfunction

function! s:GetTypingWord()
  return easycomplete#util#GetTypingWord()
endfunction

" 根据 vim-snippets 整理出目前支持的语言种类和缩写
function! s:GetLangTypeRawStr(lang)
  return language_alias#GetLangTypeRawStr(a:lang)
endfunction

"CleverTab tab 自动补全逻辑
function! easycomplete#CleverTab()
  setlocal completeopt-=noinsert
  if pumvisible()
    return "\<C-N>"
  elseif exists("g:snipMate") && exists('b:snip_state')
    " 代码已经完成展开时，编辑代码占位符，用tab进行占位符之间的跳转
    let jump = b:snip_state.jump_stop(0)
    if type(jump) == 1 " 返回字符串
      " 等同于 return "\<C-R>=snipMate#TriggerSnippet()\<CR>"
      return jump
    endif
  elseif &filetype == "go" && strpart(getline('.'), col('.') - 2, 1) == "."
    " Hack for Golang
    " 唤醒easycomplete菜单
    setlocal completeopt+=noinsert
    return "\<C-X>\<C-U>"
  elseif getline('.')[0 : col('.')-1]  =~ '^\s*$' ||
        \ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' ||
        \ len(s:StringTrim(getline('.'))) == 0
    " 判断空行的三个条件
    "   如果整行是空行
    "   前一个字符是空格
    "   空行
    return "\<Tab>"
  elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
        \ "\\(\\w\\|\\/\\|\\.\\)$") < 0
    " 如果正在输入一个非字母，也不是'/'或'.'
    return "\<Tab>"
  elseif exists("g:snipMate")
    " let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
    " let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)

    " 如果只匹配一个，也还是给出提示
    return "\<C-X>\<C-U>"
  else
    " 正常逻辑下都唤醒easycomplete菜单
    return "\<C-X>\<C-U>"
  endif
endfunction

" CleverShiftTab 逻辑判断，无补全菜单情况下输出<Tab>
" Shift-Tab 在插入模式下输出为 Tab，仅为我个人习惯
function! easycomplete#CleverShiftTab()
  return pumvisible()?"\<C-P>":"\<Tab>"
endfunction

" 回车事件的行为，如果补全浮窗内点击回车，要判断是否
" 插入 snipmete 展开后的代码，否则还是默认回车事件
function! TypeEnterWithPUM()
  " 如果浮窗存在且 snipMate 已安装
  if pumvisible() && exists("g:snipMate")
    " 得到当前光标处已匹配的单词
    let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
    " 根据单词查找 snippets 中的匹配项
    let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)
    " 关闭浮窗

    " 1. 优先判断是否前缀可被匹配 && 是否完全匹配到 snippet
    if snipMate#CanBeTriggered() && !empty(list)
      call s:CloseCompletionMenu()
      call feedkeys( "\<Plug>snipMateNextOrTrigger" )
      return ""
    endif

    " 2. 如果安装了 jedi，回车补全单词
    if &filetype == "python" &&
          \ exists("g:jedi#auto_initialization") &&
          \ g:jedi#auto_initialization == 1
      return "\<C-Y>"
    endif
  endif
  if pumvisible()
    return "\<C-Y>"
  endif
  return "\<CR>"
endfunction

" 将 snippets 原始格式做简化，用作浮窗提示展示用
" 主要将原有格式里的占位符替换成单个单词，比如下面是原始串
" ${1:obj}.ajaxSend(function (${1:request, settings}) {
" 替换为=>
" obj.ajaxSend(function (request, settings) {
function! s:GetSnippetSimplified(snippet_str)
  let pfx_len = match(a:snippet_str,"${[0-9]:")
  if !empty(a:snippet_str) && pfx_len < 0
    return a:snippet_str
  endif

  let simplified_str = substitute(a:snippet_str,"\${[0-9]:\\(.\\{\-}\\)}","\\1", "g")
  return simplified_str
endfunction

" 插入模式下模拟按键点击
function! s:SendKeys( keys )
  call feedkeys( a:keys, 'in' )
endfunction

" 将Buff关键字和Snippets做合并
" keywords is List
" snippets is Dict
function! s:MixinBufKeywordAndSnippets(keywords,snippets)
  if empty(a:snippets) || len(a:snippets) == 0
    return a:keywords
  endif

  let snipabbr_list = []
  for [k,v] in items(a:snippets)
    let snip_obj  = s:GetSnip(v)
    let snip_body = s:MenuStringTrim(get(snip_obj,'snipbody'))
    let menu_kind = s:StringTrim(s:GetLangTypeRawStr(get(snip_obj,'langtype')))
    " kind 内以尖括号表示语言类型
    " let menu_kind = substitute(menu_kind,"\\[\\(\\w\\+\\)\\]","\<\\1\>","g")
    call add(snipabbr_list, {"word": k , "menu": snip_body, "kind": menu_kind})
  endfor

  call extend(snipabbr_list , a:keywords)
  return snipabbr_list
endfunction

" 从一个完整的SnipObject中得到Snippet最有用的两个信息
" 一个是snip原始代码片段，一个是语言类型
function! s:GetSnip(snipobj)
  let errmsg    = "[Unknown snippet]"
  let snip_body = ""
  let lang_type = ""

  if empty(a:snipobj)
    let snip_body = errmsg
  else
    let v = values(a:snipobj)
    let k = keys(a:snipobj)
    if !empty(v[0]) && !empty(k[0])
      let snip_body = v[0][0]
      let lang_type = split(k[0], "\\s")[0]
    else
      let snip_body = errmsg
    endif
  endif
  return {"snipbody":snip_body,"langtype":lang_type}
endfunction

" 相当于 trim，去掉首尾的空字符
function! s:StringTrim(str)
  if !empty(a:str)
    let a1 = substitute(a:str, "^\\s\\+\\(.\\{\-}\\)$","\\1","g")
    let a1 = substitute(a:str, "^\\(.\\{\-}\\)\\s\\+$","\\1","g")
    return a1
  endif
  return ""
endfunction

" 弹窗内需要展示的代码提示片段的 'Trim'
function! s:MenuStringTrim(localstr)
  let default_length = 28
  let simplifed_result = s:GetSnippetSimplified(a:localstr)

  if !empty(simplifed_result) && len(simplifed_result) > default_length
    let trim_str = simplifed_result[:default_length] . ".."
  else
    let trim_str = simplifed_result
  endif

  return split(trim_str,"[\n]")[0]
endfunction

" 如果 vim-snipmate 已经安装，用这个插件的方法取 snippets
function! g:GetSnippets(scopes, trigger) abort
  if exists("g:snipMate")
    return snipMate#GetSnippets(a:scopes, a:trigger)
  endif
  return {}
endfunction

" 关闭补全浮窗
function! s:CloseCompletionMenu()
  if pumvisible()
    call s:SendKeys( "\<ESC>a" )
  endif
endfunction

" 判断当前是否正在输入一个地址path
" base 原本想传入当前文件名字，实际上传不进来，这里也没用到
function! easycomplete#TypingAPath(findstart, base)
  " 这里不清楚为什么
  " 输入 ./a/b/c ，./a/b/  两者得到的prefx都为空
  " 前者应该得到 c
  " 这里只能临时将base透传进来表示文件名
  let line  = getline('.')
  let coln  = col('.') - 1
  let prefx = ' ' . line[0:coln - 1]

  " Hack: 第二次进来 getline('.')时把光标所在的字符吃掉了，原因不明
  " 所以这里临时存一下 line 的值
  if exists('l:tmp_line_str') && a:findstart == 1
    let l:tmp_line_str = line
  elseif exists('l:tmp_line_str') && a:findstart == 0
    let line = l:tmp_line_str
    unlet l:tmp_line_str
  endif

  " 需要注意，参照上一个注释，fpath和spath只是path，没有filename
  " 从正在输入的一整行字符(行首到光标)中匹配出一个path出来
  " TODO 正则不严格，需要优化，下面这几个情况匹配要正确
  "   \ a <Tab>  => done
  "   \<Tab> => done
  "   xxxss \ xxxss<Tab> => done
  "   "/<tab>" => 不起作用, fixed at 2019-09-28
  let fpath = matchstr(prefx,"\\([\\(\\) \"'\\t\\[\\]\\{\\}]\\)\\@<=" .
        \   "\\([\\/\\.\\~]\\+[\\.\\/a-zA-Z0-9\\_\\- ]\\+\\|[\\.\\/]\\)")

  " 兼容单个 '/' 匹配的情况
  let spath = s:GetPathName( substitute(fpath,"^[\\.\\/].*\\/","./","g") )
  " 清除对 '\' 的路径识别
  let fpath = s:GetPathName(fpath)

  let pathDict                 = {}
  let pathDict.line            = line
  let pathDict.prefx           = prefx
  " fname 暂没用上，放这里备用
  let pathDict.fname           = s:GetFileName(prefx)
  let pathDict.fpath           = fpath " fullpath
  let pathDict.spath           = spath " shortpath
  let pathDict.full_path_start = coln - len(fpath) + 2
  if trim(pathDict.fname) == ''
    let pathDict.short_path_start = coln - len(spath) + 2
  else
    let pathDict.short_path_start = coln - len(pathDict.fname)
  endif

  " 排除掉输入注释的情况
  " 因为如果输入'//'紧跟<Tab>不应该出<C-X><C-U><C-N>出补全菜单
  if len(fpath) == 0 || match(prefx,"\\(\\/\\/\\|\\/\\*\\)") >= 0
    let pathDict.isPath = 0
  else
    let pathDict.isPath = 1
  endif

  return pathDict
endfunction

" 根据输入的 path 匹配出结果，返回的是一个List ['f1','f2','d1','d2']
" 查询条件实际上是用 base 来做的，typing_path 里无法包含当前敲入的filename
" ./ => 基于当前 bufpath 查询
" ../../ => 当前buf文件所在的目录向上追溯2次查询
" /a/b/c => 直接从根查询
" TODO ~/ 的支持
function! s:GetDirAndFiles(typing_path, base)
  let fpath   = a:typing_path.fpath
  let fname   = bufname('%')
  let bufpath = s:GetPathName(fname)

  if len(fpath) > 0 && fpath[0] == "."
    let path = simplify(bufpath . fpath)
  else
    let path = simplify(fpath)
  endif

  if a:base == ""
    " 查找目录下的文件和目录
    let result_list = systemlist('ls '. path .
          \ " 2>/dev/null")
  else
    " 这里没考虑Cygwin的情况
    let result_list = systemlist('ls '. s:GetPathName(path) .
          \ " 2>/dev/null")
    " 使用filter过滤，没有使用grep过滤，以便后续性能调优
    " TODO：当按<Del>键时，自动补全窗会跟随匹配，但无法做到忽略大小写
    " 只有首次点击<Tab>时能忽略大小写，
    " 应该在del跟随和tab时都忽略大小写才对
    let result_list = filter(result_list,
          \ 'tolower(v:val) =~ "^'. tolower(a:base) . '"')
  endif

  return s:GetWrappedFileAndDirsList(result_list, s:GetPathName(path))
endfunction

" 将某个目录下查找出的列表 List 的每项识别出目录和文件
" 并转换成补全浮窗所需的展示格式
function! s:GetWrappedFileAndDirsList(rlist, fpath)
  if len(a:rlist) == 0
    return []
  endif

  let result_with_kind = []

  for item in a:rlist
    let localfile = simplify(a:fpath . '/' . item)
    if isdirectory(localfile)
      call add(result_with_kind, {"word": item . "/", "kind" : "[Dir]"})
    else
      call add(result_with_kind, {"word": item , "kind" : "[File]"})
    endif
  endfor

  return result_with_kind
endfunction

" 从一个完整的 path 串中得到 FileName
" 输入的 Path 串可以带有文件名
function! s:GetFileName(path)
  let path  = simplify(a:path)
  let fname = matchstr(path,"\\([\\/]\\)\\@<=[^\\/]\\+$")
  return fname
endfunction

" 同上
function! s:GetPathName(path)
  let path =  simplify(a:path)
  let pathname = matchstr(path,"^.*\\/")
  return pathname
endfunction

" 根据词根返回语法匹配的结果，每个语言都需要单独处理
function! s:GetSyntaxCompletionResult(base) abort
  let syntax_complete = []
  " 处理 Javascript 语法匹配
  if s:IsTsSyntaxCompleteReady()
    call tsuquyomi#complete(0, a:base)
    " tsuquyomi#complete 这里先创建菜单再 complete_add 进去
    " 所以这里 ts_comp_result 总是空
    let syntax_complete = []
  endif
  " 处理 Go 语法匹配
  if s:IsGoSyntaxCompleteReady()
    if !exists("g:g_syntax_completions")
      let g:g_syntax_completions = [1,[]]
    endif
    let syntax_complete = g:g_syntax_completions[1]
  endif
  return syntax_complete
endfunction

function! s:IsGoSyntaxCompleteReady()
  if &filetype == "go" && exists("g:go_loaded_install")
    return 1
  else
    return 0
  endif
endfunction

function! s:IsTsSyntaxCompleteReady()
  if exists('g:loaded_tsuquyomi') && exists('g:tsuquyomi_is_available') &&
        \ g:loaded_tsuquyomi == 1 &&
        \ g:tsuquyomi_is_available == 1 &&
        \ &filetype =~ "^\\(typescript\\|javascript\\)"
    return 1
  else
    return 0
  endif
endfunction

" 补全菜单展示逻辑入口，光标跟随或者<Tab>键呼出
" 由于性能问题，推荐<Tab>键呼出
" 菜单格式说明（参照 YouCompleteMe 的菜单格式）
" 目前包括四类：当前缓冲区keywords，字典keywords，代码片段缩写，目录查找
" 其中目录查找和其他三类不混排（同样参照 YouCompleteMe的逻辑）
" 补全菜单格式样例 =>
"   Function    [JS]    javascript function PH (a,b)
"   fun         [ID]
"   Funny       [ID]
"   Function    [ID]    common.dict
"   function    [ID]    node.dict
"   ./Foo       [File]
"   ./b/        [Dir]
function! easycomplete#completeFunc(findstart, base)
  " TODO 实际没用上
  let l:line_str = getline('.')
  let l:line = line('.')
  let l:offset = col('.')

  " search backwards for start of identifier (iskeyword pattern)
  let l:start = l:offset
  while l:start > 0 && l:line_str[l:start-2] =~ "\\k"
    let l:start -= 1
  endwhile

  if(a:findstart)
    return l:start - 1
  endif

  call s:doComplete()
  return v:none
endfunction

function! s:completeHandler()
  call s:completeStopChecking()
  call s:StopAsyncRun()
  if s:NotInsertMode()
    return
  endif
  let l:ctx = easycomplete#context()
  if strwidth(l:ctx['typing']) == 0 && l:ctx['char'] != '.'
    return
  endif
  call s:CompleteInit()
  call s:CompletorCalling()
endfunction

function! s:completeStopChecking()
  if complete_check()
    call feedkeys("\<C-E>")
  endif
endfunction

function! s:CompleteInit(...)
  if !exists('a:1')
    let l:word = s:GetTypingWord()
  else
    let l:word = a:1
  endif
  " 这一步会让 complete popup 闪烁一下
  " call complete(col('.') - strwidth(l:word), [""])
  let g:easycomplete_menuitems = []
  
  " 由于 complete menu 是异步构造的，所以从敲入字符到 complete 呈现之间有一个
  " 时间，为了避免这个时间造成 complete 闪烁，这里设置了一个”视觉残留“时间
  if exists('g:easycomplete_visual_delay') && g:easycomplete_visual_delay > 0
    call timer_stop(g:easycomplete_visual_delay)
  endif
  let g:easycomplete_visual_delay = timer_start(100, function("s:completeMenuResetHandler"))
endfunction

function! s:completeMenuResetHandler(...)
  if !exists("g:easycomplete_menuitems") || empty(g:easycomplete_menuitems)
    call s:CloseCompletionMenu()
  endif
endfunction

function! easycomplete#CompleteAdd(menu_list)
  " 单词匹配表
  if !exists('g:easycomplete_menucache')
    call s:SetupCompleteCache()
  endif

  " 当前匹配
  if !exists('g:easycomplete_menuitems')
    let g:easycomplete_menuitems = []
  endif

  let g:easycomplete_menuitems = g:easycomplete_menuitems + s:normalizeMenulist(a:menu_list)

  let start_pos = col('.') - strwidth(s:GetTypingWord())
  call complete(start_pos, g:easycomplete_menuitems)
  call s:AddCompleteCache(s:GetTypingWord(), g:easycomplete_menuitems)
endfunction


function! s:normalizeMenulist(arr)
  if empty(a:arr)
    return []
  endif
  let l:menu_list = []

  for item in a:arr
    if type(item) == type("")
      let l:menu_item = { 'word': item,
            \ 'menu': '',
            \ 'user_data': '',
            \ 'info': '',
            \ 'kind': '',
            \ 'abbr': '' }
      call add(l:menu_list, l:menu_item)
    endif
    if type(item) == type({})
      call add(l:menu_list, extend({'word': '', 'menu': '', 'user_data': '',
            \                       'info': '', 'kind': '', 'abbr': ''},
            \ item ))
    endif
  endfor
  return l:menu_list
endfunction

function! s:CompleteAdd(...)
  return call("easycomplete#CompleteAdd", a:000)
endfunction

function! s:CompleteFilter(raw_menu_list)
  " call s:log(a:raw_menu_list)
  let arr = []
  let word = s:GetTypingWord()
  if empty(word)
    return a:raw_menu_list
  endif
  for item in a:raw_menu_list
    if strwidth(matchstr(item.word, word)) >= 1
      call add(arr, item)
    endif
  endfor
  return arr
endfunction

function! s:ShowCompletePopup()
  if s:NotInsertMode()
    return
  endif
  call s:SendKeys("\<C-P>")
endfunction

function! easycomplete#UpdateCompleteInfo()
  let item = v:event.completed_item
  let info = {"word":"1","menu":"sdf","kind":"sdfsdf"}
  call s:ShowCompleteInfo(info)
endfunction

function! s:ShowCompleteInfo(info)
  let id = popup_findinfo()
  if id
    call popup_settext(id, 'async info: ')
    call popup_show(id)
  endif
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction

function! s:StopAsyncRun(...)
  return call('easycomplete#util#StopAsyncRun', a:000)
endfunction

function! s:NotInsertMode()
  return call('easycomplete#util#NotInsertMode', a:000)
endfunction

function! s:log(msg)
  setlocal ch=10
  setlocal cmdwinheight=10
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction

function! easycomplete#log(msg)
  call s:log(a:msg)
endfunction

