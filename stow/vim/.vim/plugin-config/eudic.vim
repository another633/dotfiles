" function! Eudic(...)
" 	" 获取寄存器"的文本
" 	let l:word = getreg('"')
" 	if a:0 >= 1
" 		let l:word = a:1
" 	endif
" 	let l:result = system("eudic " . shellescape(l:word))
" 	if l:result != ''
" 		echo "Error occurred: " . l:result
" 	endif
" endfunction

" command! -nargs=? Eudic call Eudic(<f-args>)
