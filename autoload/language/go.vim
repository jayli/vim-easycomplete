" 支持go语言的 omni 自动匹配
" https://github.com/jayli/gocode/blob/master/vim/autoload/gocomplete.vim

function! s:gocodeCurrentBuffer()
	let buf = getline(1, '$')
	if &encoding != 'utf-8'
		let buf = map(buf, 'iconv(v:val, &encoding, "utf-8")')
	endif

	if &l:fileformat == 'dos'
		let buf = map(buf, 'v:val."\r"')
	endif

	let file = tempname()
	call writefile(buf, file)
	return file
endfunction

function! s:system(cmd, ...) abort
	return call('system', [a:cmd] + a:000)
endfunction

function! s:gocodeShellescape(arg)
	try
		let ssl_save = &shellslash
		set noshellslash
		return shellescape(a:arg)
	finally
		let &shellslash = ssl_save
	endtry
endfunction


function! s:gocodeCommand(cmd, preargs, args)
	for i in range(0, len(a:args) - 1)
		let a:args[i] = s:gocodeShellescape(a:args[i])
	endfor
	for i in range(0, len(a:preargs) - 1)
		let a:preargs[i] = s:gocodeShellescape(a:preargs[i])
	endfor
	let cmd_line = printf('gocode %s %s %s', join(a:preargs), a:cmd, join(a:args))
	let result = s:system(printf('gocode %s %s %s', join(a:preargs), a:cmd, join(a:args)))
	call s:LogMsg(cmd_line)
	call s:LogMsg(result)
	if v:shell_error != 0
		return "[\"0\", []]"
	else
		if &encoding != 'utf-8'
			let result = iconv(result, 'utf-8', &encoding)
		endif
		return result
	endif
endfunction

function! s:gocodeCurrentBufferOpt(filename)
	return '-in=' . a:filename
endfunction

function! s:gocodeCursor()
	if &encoding != 'utf-8'
		let c = col('.')
		let buf = line('.') == 1 ? "" : (join(getline(1, line('.')-1), "\n") . "\n")
		let buf .= c == 1 ? "" : getline('.')[:c-2]
		return printf('%d', len(iconv(buf, &encoding, "utf-8")))
	endif
	return printf('%d', line2byte(line('.')) + (col('.')-2))
endfunction

function! s:gocodeAutocomplete()
	let filename = s:gocodeCurrentBuffer()
	let result = s:gocodeCommand('autocomplete',
				   \ [s:gocodeCurrentBufferOpt(filename), '-f=vim'],
				   \ [expand('%:p'), s:gocodeCursor()])
	call delete(filename)
	return result
endfunction

function language#go#GocodeAutocomplete()
	return s:gocodeAutocomplete()
endfunction

function! language#go#Complete(findstart, base)
	"findstart = 1 when we need to get the text length
	if a:findstart == 1
		execute "silent let g:gocomplete_completions = " . s:gocodeAutocomplete()
		return col('.') - g:gocomplete_completions[0] - 1
	"findstart = 0 when we need to return the list of completions
	else
		return g:gocomplete_completions[1]
	endif
endfunction

function! s:LogMsg(msg)
	echohl MoreMsg
	echom '>>> '. a:msg
	echohl NONE
endfunction
