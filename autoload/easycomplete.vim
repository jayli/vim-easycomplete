" File:			easycomplete.vim
" Author:		@jayli <https://github.com/jayli/>
" Description:	easycomplete.vim 是 vim-easycomplete 插件的启动文件，
"				easycomplete 实现了针对字典和 buff keyword 的自动补全，不依赖
"				于其他语言，完全基于 VimL 实现，安装比较干净，同时该插件兼容了
"				snipMate 和其携带的 snipets 代码片段，书写代码超级舒服
"				改文件是主要的逻辑，说明均已注释跟随在代码里
"
"				更多信息：
"					<https://github.com/jayli/vim-easycomplete>
"				Thanks for SnipMate: 
"					<https://www.vim.org/scripts/script.php?script_id=2540>
"
" TODO:
" - [fixed] 如果一个单词刚好只有一个匹配，或者匹配不出东西，点击tab是没有反应
" - [fixed] 各种补全形态的支持，包括支持 File 匹配
" - [doing] 各种语言的词表收集,doing
" - [later] js include 的文件词表生成记录入buf
" - [later] ":"隔断的单词匹配不出来,later
" - [later] 单词位置的就近匹配
" - [later] snip 词表排序

" 插件初始化入口
function! easycomplete#Enable()
	" VI 兼容模式，连续输入时的popup兼容性好
	set cpoptions+=B
	" completeopt 需要设置成 menuone，不然如果只有一个展示
	" 列表时，菜单往往无法弹出
	set completeopt-=menu
	set completeopt+=menuone
	" 这个是非必要设置，通常用来表示可以为所有匹配项插入通用前缀符，这样就可以
	" 为不同匹配项设置特定的标识，这个插件不需要这么复杂的设置。同时，设置
	" longest 为贪婪匹配，这里不需要
	set completeopt-=longest
	" noselect 可配可不配
	"set completeopt+=noselect
	" <C-X><C-U><C-N>时触发默认关键词匹配，函数劫持至此
	let &completefunc = 'easycomplete#CompleteFunc'
	" 插入模式下的回车事件监听
	inoremap <expr> <CR> TypeEnterWithPUM()
	" 插入模式下 Tab 和 Shift-Tab 的监听
	" inoremap <Tab> <C-R>=CleverTab()<CR>
	" inoremap <S-Tab> <C-R>=CleverShiftTab()<CR>
	inoremap <silent> <Plug>EasyCompTabTrigger  <C-R>=easycomplete#CleverTab()<CR>
	inoremap <silent> <Plug>EasyCompShiftTabTrigger  <C-R>=easycomplete#CleverShiftTab()<CR>

endfunction

" 根据 vim-snippets 整理出目前支持的语言种类和缩写
"function s:GetLangTypeRawStr(lang) {{{
function! s:GetLangTypeRawStr(lang)
	let lang_abbr = {}
	
	let lang_abbr['_']               = "[_]"
	let lang_abbr['actionscript']    = "[As]"
	let lang_abbr['ada']             = "[Ada]"
	let lang_abbr['alpaca']          = "[alp]"
	let lang_abbr['apache']          = "[apa]"
	let lang_abbr['arduino']         = "[ard]"
	let lang_abbr['autoit']          = "[aut]"
	let lang_abbr['awk']             = "[Awk]"
	let lang_abbr['c']               = "[C]"
	let lang_abbr['chef']            = "[chef]"
	let lang_abbr['clojure']         = "[cloj]"
	let lang_abbr['cmake']           = "[cmk]"
	let lang_abbr['codeigniter']     = "[code]"
	let lang_abbr['coffee']          = "[coff]"
	let lang_abbr['cpp']             = "[Cpp]"
	let lang_abbr['crystal']         = "[cyl]"
	let lang_abbr['cs']              = "[Cs]"
	let lang_abbr['css']             = "[Css]"
	let lang_abbr['cuda']            = "[cuda]"
	let lang_abbr['d']               = "[D]"
	let lang_abbr['dart']            = "[dart]"
	let lang_abbr['django']          = "[dja]"
	let lang_abbr['dosini']          = "[Dos]"
	let lang_abbr['eelixir']         = "[elix]"
	let lang_abbr['elixir']          = "[elix]"
	let lang_abbr['elm']             = "[elm]"
	let lang_abbr['erlang']          = "[elng]"
	let lang_abbr['eruby']           = "[Ruby]"
	let lang_abbr['falcon']          = "[falc]"
	let lang_abbr['fortran']         = "[fort]"
	let lang_abbr['go']              = "[Go]"
	let lang_abbr['haml']            = "[haml]"
	let lang_abbr['handlebars']      = "[hand]"
	let lang_abbr['haskell']         = "[hskl]"
	let lang_abbr['html']            = "[Html]"
	let lang_abbr['htmldjango']      = "[Html]"
	let lang_abbr['htmltornado']     = "[Html]"
	let lang_abbr['idris']           = "[diri]"
	let lang_abbr['jade']            = "[Jade]"
	let lang_abbr['java']            = "[Java]"
	let lang_abbr['javascript']      = "[JS]"
	let lang_abbr['jinja']           = "[jinj]"
	let lang_abbr['jsp']             = "[JSP]"
	let lang_abbr['julia']           = "[jul]"
	let lang_abbr['kotlin']          = "[kotl]"
	let lang_abbr['laravel']         = "[lar]"
	let lang_abbr['ledger']          = "[ledg]"
	let lang_abbr['lfe']             = "[lfe]"
	let lang_abbr['ls']              = "[Ls]"
	let lang_abbr['lua']             = "[Lua]"
	let lang_abbr['make']            = "[Make]"
	let lang_abbr['mako']            = "[Mako]"
	let lang_abbr['markdown']        = "[mkd]"
	let lang_abbr['matlab']          = "[mtl]"
	let lang_abbr['mustache']        = "[mst]"
	let lang_abbr['objc']            = "[OC]"
	let lang_abbr['ocaml']           = "[OC]"
	let lang_abbr['openfoam']        = "[opf]"
	let lang_abbr['perl']            = "[Perl]"
	let lang_abbr['perl6']           = "[Perl]"
	let lang_abbr['php']             = "[Php]"
	let lang_abbr['plsql']           = "[Sql]"
	let lang_abbr['po']              = "[po]"
	let lang_abbr['processing']      = "[prc]"
	let lang_abbr['progress']        = "[prg]"
	let lang_abbr['ps1']             = "[Ps1]"
	let lang_abbr['puppet']          = "[ppt]"
	let lang_abbr['purescript']      = "[ps]"
	let lang_abbr['python']          = "[PY]"
	let lang_abbr['r']               = "[R]"
	let lang_abbr['rails']           = "[Rail]"
	let lang_abbr['reason']          = "[rea]"
	let lang_abbr['rst']             = "[Rst]"
	let lang_abbr['ruby']            = "[Ruby]"
	let lang_abbr['rust']            = "[Rust]"
	let lang_abbr['sass']            = "[Sass]"
	let lang_abbr['scala']           = "[scl]"
	let lang_abbr['scheme']          = "[sch]"
	let lang_abbr['scss']            = "[scss]"
	let lang_abbr['sh']              = "[SH]"
	let lang_abbr['simplemvcf']      = "[spm]"
	let lang_abbr['slim']            = "[slim]"
	let lang_abbr['snippets']        = "[snp]"
	let lang_abbr['sql']             = "[sql]"
	let lang_abbr['stylus']          = "[stl]"
	let lang_abbr['supercollider']   = "[sup]"
	let lang_abbr['systemverilog']   = "[SYS]"
	let lang_abbr['tcl']             = "[TCL]"
	let lang_abbr['tex']             = "[TEX]"
	let lang_abbr['textile']         = "[TEX]"
	let lang_abbr['twig']            = "[twi]"
	let lang_abbr['typescript']      = "[TS]"
	let lang_abbr['typescriptreact'] = "[TS]"
	let lang_abbr['verilog']         = "[vrl]"
	let lang_abbr['vhdl']            = "[vhdl]"
	let lang_abbr['vim']             = "[VIM]"
	let lang_abbr['vue']             = "[VUE]"
	let lang_abbr['xml']             = "[XML]"
	let lang_abbr['xslt']            = "[xslt]"
	let lang_abbr['yii']             = "[YII]"
	let lang_abbr['zsh']             = "[ZSH]"

	return has_key(lang_abbr, a:lang) ? get(lang_abbr, a:lang) : "[Ukn]"
endfunction
"}}}

"CleverTab tab 自动补全逻辑
function! easycomplete#CleverTab()
	if pumvisible()
		return "\<C-N>"
	elseif exists("g:snipMate") && exists('b:snip_state') 
		" 代码已经完成展开时，编辑代码占位符，用tab进行占位符之间的跳转
		let jump = b:snip_state.jump_stop(0)
		if type(jump) == 1 " 返回字符串
			" 等同于 return "\<C-R>=snipMate#TriggerSnippet()\<CR>"
			return jump
		endif
	elseif getline('.')[0 : col('.')-1]  =~ '^\s*$' || 
				\ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' || 
				\ len(s:StringTrim(getline('.'))) == 0 
		" 如果整行是空行
		" 前一个字符是空格
		" 空行
		return "\<Tab>"
	elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
												\ "\\(\\w\\|\\/\\)$") < 0
		" 如果正在输入一个非字母，也不是'/'
		return "\<Tab>"
	elseif exists("g:snipMate")
		let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
		let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)

		if snipMate#CanBeTriggered() && !empty(list) && len(list) == 1
			call feedkeys( "\<Plug>snipMateNextOrTrigger" )
			return ""
		else
			"唤醒easycomplete菜单
			return "\<C-X>\<C-U>"
		endif
	else
		"唤醒easycomplete菜单
		return "\<C-X>\<C-U>"
	endif
endfunction

" CleverShiftTab 逻辑判断，无补全菜单情况下输出<Tab>
" Shift-Tab 在插入模式下输出为 Tab，是我个人习惯
" TODO 是否要抽离到 vimrc 中？
function! easycomplete#CleverShiftTab()
	return pumvisible()?"\<C-P>":"\<Tab>"
endfunction

" 回车事件的行为，如果补全浮窗内点击回车，要判断是否
" 插入 snipmete 展开后的代码，否则还是默认回车事件
function! TypeEnterWithPUM()
	" 如果浮窗存在
	if pumvisible()
		if exists("g:snipMate")
			" 得到当前光标处已匹配的单词
			let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
			" 根据单词查找 snippets 中的匹配项
			let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)
			" 关闭浮窗
			call s:CloseCompletionMenu()

			"是否前缀可被匹配 && 是否完全匹配到snippet
			if snipMate#CanBeTriggered() && !empty(list)
				call feedkeys( "\<Plug>snipMateNextOrTrigger" )
			endif
			return ""
		else
			call s:CloseCompletionMenu()
			return ""
		endif
	else
		"除此之外还是回车的正常行为
		return "\<CR>"
	endif
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
		let menu_kind = substitute(menu_kind,"\\[\\(\\w\\+\\)\\]","\<\\1\>","g")
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
		return substitute(a:str, "^\\s\\+\\(.\\{\-}\\)\\s\\+$","\\1","g")
	endif
	return ""
endfunction

" 弹窗内需要展示的代码提示片段的 'Trim'
function! s:MenuStringTrim(localstr)
	let default_length = 33
	let simplifed_result = s:GetSnippetSimplified(a:localstr)

	if !empty(simplifed_result) && len(simplifed_result) > default_length 
		let trim_str = simplifed_result[:default_length] . ".."
	else
		let trim_str = simplifed_result 
	endif

	return split(trim_str,"[\n]")[0]
endfunction

" 如果 vim-snipmate 已经安装，用这个插件的方法取 snippets
function! g:GetSnippets(scopes, trigger)
	if exists("g:snipMate")
		return snipMate#GetSnippets(a:scopes, a:trigger)
	endif
	return {}
endfunction

" 读取缓冲区词表和字典词表，两者合并输出大词表
function! s:GetKeywords(base)
	let bufKeywordList        = s:GetBufKeywordsList()
	let wrappedBufKeywordList = s:GetWrappedBufKeywordList(bufKeywordList)
	return s:MenuArrayDistinct(extend(
			\		wrappedBufKeywordList,
			\		s:GetWrappedDictKeywordList()
			\	),
			\	a:base)
endfunction

"popup 菜单内关键词去重，只做buff和dict里的keyword去重
"传入的 list 不应包含 snippet 缩写
"base 是要匹配的原始字符串
function! s:MenuArrayDistinct(menuList, base)
	if empty(a:menuList) || len(a:menuList) == 0
		return []
	endif

	let menulist_tmp = []
	for item in a:menuList
		call add(menulist_tmp, item.word)
	endfor

	let menulist_filter = uniq(filter(menulist_tmp,
						\ 'matchstrpos(v:val, "'.a:base.'")[1] == 0'))

	"[word1,word2,word3...]
	let menulist_assetlist = [] 
	"[{word:word1,kind..},{word:word2,kind..}..]
	let menulist_result = [] 

	for item in a:menuList
		let word = get(item, "word")
		if index(menulist_assetlist, word) >= 0
			continue
		elseif index(menulist_filter, word) >= 0
			call add(menulist_result,deepcopy(item))
			call add(menulist_assetlist, word)
		endif
	endfor

	return menulist_result
endfunction

" 获取当前所有 buff 内的关键词列表
function! s:GetBufKeywordsList()
	let tmpkeywords = []
	for buf in getbufinfo()
		let lines = getbufline(buf.bufnr, 1 ,"$")
		for line in lines
			" 获取 buff keyword 的正则表达式
			call extend(tmpkeywords, split(line,'[^A-Za-z0-9_#]'))
		endfor
	endfor

	let keywordList = s:ArrayDistinct(tmpkeywords)
	let keywordFormedList = []
	for v in keywordList
		call add(keywordFormedList, v )
	endfor

	return keywordFormedList
endfunction

" 将 Buff 关键词简单列表转换为补全浮窗所需的列表格式
" 比如原始简单列表是 ['abc','def','efd'] ，输出为
" => [{"word":"abc","kind":"[ID]"},{"word":"def","kind":"[ID]"}...]
function! s:GetWrappedBufKeywordList(keywordList)
	if empty(a:keywordList) || len(a:keywordList) == 0
		return []
	endif
	
	let wrappedList = []
	for word_str in a:keywordList
		call add(wrappedList,{"word":word_str,"kind":"[ID]"})
	endfor
	return wrappedList
endfunction

" 将字典简单词表转换为补全浮窗所需的列表格式
" 比如字典原始列表为 ['abc','def'] ，输出为
" => [{"word":'abc',"kind":"[ID]","menu":"common.dict"}...]
function! s:GetWrappedDictKeywordList()
	if exists("b:globalDictKeywords")
		return b:globalDictKeywords
	endif

	let b:globalDictKeywords = []

	" 如果当前 Buff 所读取的字典目录存在
	if !empty(&dictionary)
		let dictsFiles   = split(&dictionary,",")
		let dictkeywords = []
		for onedict in dictsFiles 
			try
				let lines = readfile(onedict)
			catch /.*/
				"echoe "关键词字典不存在!请删除该字典配置 ". 
				"			\ "dictionary-=".onedict
				continue
			endtry

			let filename         = substitute(onedict,"^.\\+[\\/]","","g")
			let localdicts       = []
			let localWrappedList = []

			if empty(lines)
				continue
			endif

			for line in lines
				call extend(localdicts, split(line,'[^A-Za-z0-9_#]'))
			endfor

			let localdicts = s:ArrayDistinct(localdicts)

			for item in localdicts
				call add (dictkeywords, {
								\	"word" : item ,
								\	"kind" : "[ID]",
								\	"menu" : filename 
								\ })
			endfor
		endfor

		let b:globalDictKeywords = dictkeywords
		return dictkeywords
	else 
		return []
	endif
endfunction

" List 去重，类似 uniq，纯数字要去掉
function! s:ArrayDistinct( list )
	if empty(a:list)
		return []
	else
		let tmparray = [] 
		let uniqlist = uniq(a:list)
		for item in uniqlist
			if !empty(item) && 
					\ !str2nr(item) &&
					\ len(item) != 1
				call add(tmparray,item)
			endif
		endfor
		return tmparray
	endif
endfunction

" 关闭补全浮窗
function! s:CloseCompletionMenu()
	if pumvisible()
		call s:SendKeys( "\<ESC>a" )
	endif
endfunction

" 判断当前是否正在输入一个地址path
" base 原本想传入当前文件名字，实际上传不进来，这里也没用到
function! easycomplete#TypingAPath(base)
	" 这里不清楚为什么
	" 输入 ./a/b/c ，./a/b/  两者得到的prefx都为空
	" 前者应该得到 c
	" 这里只能临时将base透传进来表示文件名
	let line  = getline('.')
	let coln  = col('.') - 1
	let prefx = ' ' . line[0:coln]

	" 需要注意，参照上一个注释，fpath和spath只是path，没有filename
	" 从正在输入的一整行字符(行首到光标)中匹配出一个path出来
	" TODO（fixed） 正则不严格，需要优化，下面这几个情况匹配要正确
	"	\ a <Tab>
	"	\<Tab>
	"	asdf \ asdf<Tab> 
	let fpath = matchstr(prefx,"\\([\\(\\) \"'\\t\\[\\]\\{\\}]\\)\\@<=" .
				\	"\\([\\/\\.]\\+[\\.\\/a-zA-Z0-9\\_\\- ]\\+\\|[\\.\\/]\\)") 

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
	if pathDict.fname == ''
		let pathDict.short_path_start = coln - len(spath) + 2
	else
		let pathDict.short_path_start = coln - len(pathDict.fname)
	endif

	" 排除掉输入注释的情况
	" TODO: bug => 如果输入'//'紧跟<Tab>出来仍然会<C-X><C-U><C-N>出补全菜单
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

" 补全菜单展示逻辑入口，光标跟随或者<Tab>键呼出
" 由于性能问题，推荐<Tab>键呼出
" 菜单格式说明（参照 YouCompleteMe 的菜单格式）
" 目前包括四类：当前缓冲区keywords，字典keywords，代码片段缩写，目录查找
" 其中目录查找和其他三类不混排（同样参照 YouCompleteMe的逻辑）
" 补全菜单格式样例 =>
"	Function	[JS]	javascript function PH (a,b)
"	fun			[ID]
"	Funny		[ID]
"	Function	[ID]	common.dict
"	function	[ID]	node.dict
"	./Foo		[File]
"	./b/		[Dir]
function! easycomplete#CompleteFunc( findstart, base )
	let typing_path = easycomplete#TypingAPath(a:base)

	" 如果正在敲入一个文件路径
	if typing_path.isPath && a:findstart
		" 兼容这几种情况 =>
		" ./a/b/c/d
		" ../asdf./
		" /a/b/c/ds
		" /a/b/c/d/
		return typing_path.short_path_start
	elseif typing_path.isPath
		" 查找目录
		let result = s:GetDirAndFiles(typing_path, a:base)
		return result
	endif

	" 常规的关键字处理
	if a:findstart
		" 定位当前关键字的起始位置
		let line = getline('.')
		let start = col('.') - 1
		" Hack: 如果是 '//' 后紧跟<Tab>，直接输出<Tab>
		if strpart(line, start - 1, 2) == '//'
			return start
		endif

		while start > 0 && line[start - 1] =~ '[a-zA-Z0-9_#]'
			let start -= 1
		endwhile
		return start
	endif

	" 获得各类关键字的匹配结果
	let keywords_result = s:GetKeywords(a:base)
	let snippets_result = g:GetSnippets(deepcopy([&filetype]),a:base)
	let all_result      = s:MixinBufKeywordAndSnippets(keywords_result, snippets_result)

	" TODO 如果匹配不出任何结果，还是执行原有按键，我这里用tab，实际上还
	" 有一种选择，暂停行为，给出match不成功的提示，我建议要强化insert输入
	" tab 用 s-tab (我个人习惯)，而不是一味求全 tab 的容错，容错不报错也
	" 是一个问题，Shift-Tab 被有些人用来设定为Tab回退，可能会被用不习惯，
	" 这里需要读者注意
	if len(all_result) == 0 || len(a:base) == 0
		call s:CloseCompletionMenu()
		call s:SendKeys("\<Tab>")
		return 0
	endif

	return all_result
endfunction

"vim: foldmethod=marker:softtabstop=4:tabstop=4:shiftwidth=4
