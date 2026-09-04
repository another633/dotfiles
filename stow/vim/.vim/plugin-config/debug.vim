let g:target = ""

function! Debug()
		call ChackTarget("程序路径")
		execute "Termdebug " . g:target
endfunction

function! DebugCommand()
	  call ChackTarget("程序路径和参数")
		execute "TermdebugCommand " . g:target
endfunction

function! ChackTarget(...)
	call IsTermdebugLoaded()
	if g:target == ""
		let g:target = input("输入" . a:1 . ": ")
	else
		let l:str = input("enter继续上一次的程序路径(" . g:target . ")，或新的" . a:1 . ": ")
		if l:str != ""
			let g:target = l:str
		endif
	endif
endfunction

function! IsTermdebugLoaded()
    " 获取 runtimepath 变量
    let rtp = &runtimepath

    " 检查 termdebug 是否在 runtimepath 中
    if rtp !~? 'termdebug'
			echo "加载:termdebug"
			packadd termdebug
    endif
endfunction

let g:runtarget = ""

function! Run_()
	  call ChangeRunTarget()
		try
			" 执行运行目标
			execute '!' . g:runtarget
		catch /E492:/
			echo "E492: 没有打开的文件"
		endtry
endfunction

function! ChangeRunTarget()
		if g:runtarget == ""
			let g:runtarget = input("输入运行目标: ")
		else
			let l:str = input("enter继续上一次的运行目标(" . g:runtarget . ")，或新的: ")
			if l:str != ""
				let g:runtarget = l:str
			endif
	 endif
endfunction
