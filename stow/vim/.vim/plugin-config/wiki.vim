function! Wiki(...)
	let l:word = getreg('"')
	if a:0 >= 1
		let l:word = a:1
	endif
	let l:result = system("wiki " . shellescape(l:word))
	if l:result != ''
		echo "Error occurred: " . l:result
	endif
endfunction

command! -nargs=? Wiki call Wiki(<f-args>)
