" 当执行 :w / :wq 导致写入时，如果 g:note_save 存在：
" 以当前缓冲区第一行作为文件名（.txt），保存一份到 ~/Notes/ 下（不存在则创建）

if exists('g:loaded_note_save_plugin')
  finish
endif
let g:loaded_note_save_plugin = 1

function! s:SanitizeFilename(name) abort
  " 去掉首尾空白
  let l:n = trim(a:name)

  " 把路径分隔符、控制字符等替换为下划线
  let l:n = substitute(l:n, '[/\\:\*\?"<>\|\x00-\x1f]', '_', 'g')

  " 空白折叠成单个空格（也可改成下划线）
  let l:n = substitute(l:n, '\s\+', ' ', 'g')

  " 防止文件名为空
  if empty(l:n)
    let l:n = strftime('note_%Y%m%d_%H%M%S')
  endif

  " 避免太长（可按需调整）
  if strlen(l:n) > 80
    let l:n = strpart(l:n, 0, 80)
  endif

  return l:n
endfunction

function! s:UniquePath(path) abort
  if !filereadable(a:path)
    return a:path
  endif

  let l:base = fnamemodify(a:path, ':r')
  let l:ext  = '.' . fnamemodify(a:path, ':e')
  let l:i = 2
  while filereadable(l:base . '-' . l:i . l:ext)
    let l:i += 1
  endwhile
  return l:base . '-' . l:i . l:ext
endfunction

function! s:SaveToNotesDir() abort
  if !exists('g:note_save')
    return
  endif

  let l:notes_dir = expand('~/Notes')

  " 没有就创建 ~/Notes
  if !isdirectory(l:notes_dir)
    call mkdir(l:notes_dir, 'p')
  endif

  " 第一行做文件名
  " 取第一行
  let l:first = getline(1)

  " 清理非法字符
  let l:first = s:SanitizeFilename(l:first)

  " 取前10个字符（不是字节）
  let l:short = strcharpart(l:first, 0, 10)

  " 如果原文本超过10字符，加 ....
  if strchars(l:first) > 10
    let l:title = l:short . '...'
  else
    let l:title = l:short
  endif

  let l:path = l:notes_dir . '/' . l:title . '.txt'
  let l:path  = s:UniquePath(l:path)

  " 写出整个缓冲内容到 Notes 目录（不影响你正在 :w 的目标文件）
  call writefile(getline(1, '$'), l:path)
endfunction

augroup NoteSaveOnWrite
  autocmd!
  " 任何写入（:w / :wq / :x 等）都会触发
  autocmd BufWritePre * call s:SaveToNotesDir()
augroup END
