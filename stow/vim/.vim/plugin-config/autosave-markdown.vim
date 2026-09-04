" 只在文件可写且未被修改时保存
augroup smart_auto_save_md
    autocmd!
    autocmd InsertLeave *.md,*.markdown call s:AutoSaveMarkdown()
augroup END

function! s:AutoSaveMarkdown()
    " 检查文件是否可写且有修改
    if &modified && &readonly == 0 && &buftype == ''
        silent! update
        echo "自动保存完成"
    endif
endfunction
