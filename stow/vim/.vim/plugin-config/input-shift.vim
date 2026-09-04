" 检查是否是在WSL中运行
if system('uname -r') =~ 'Microsoft'

let g:im_select_path = "im-select.exe"
" 1033 是英文输入法
let g:im_status="1033"

function! Im_ILeave()
	let g:im_status = system(g:im_select_path)
	call system(g:im_select_path . "1033")
endfunction

function Im_IEnter()
	call system(g:im_select_path . " " . g:im_status)
endfunction

autocmd InsertLeave * exec ":silent call Im_ILeave()"
autocmd InsertEnter * exec ":silent call Im_IEnter()"

endif
