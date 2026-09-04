" ===== 配置：根据你的 clip 实际可执行名/前缀调整 =====
" 读：无参输出剪贴板
let g:clip_read_cmd  = get(g:, 'clip_read_cmd',  'clip')
" 写：以“单个字符串参数”设置剪贴板（比如就是 'clip'）
let g:clip_write_cmd = get(g:, 'clip_write_cmd', 'clip')

if !executable(split(g:clip_read_cmd)[0])
  echohl ErrorMsg | echom "[clip] 未找到命令：" . g:clip_read_cmd | echohl None
endif
if !executable(split(g:clip_write_cmd)[0])
  echohl ErrorMsg | echom "[clip] 未找到命令：" . g:clip_write_cmd | echohl None
endif

" —— 关键：以“单参数”方式设置剪贴板（不走 stdin）——
function! s:ClipSetArg(str) abort
  " shellescape 保证整段文本作为“一个参数”传给 clip（含换行、空格、引号都可）
  let l:cmd = g:clip_write_cmd . ' ' . shellescape(a:str)
  call system(l:cmd)
  if v:shell_error
    echohl ErrorMsg | echom "[clip] 写入失败（退出码 " . v:shell_error . "）" | echohl None
  endif
endfunction

" 读取：把剪贴板内容当作多行插入
function! s:ClipGetLines() abort
  return split(system(g:clip_read_cmd), "\n", 1)
endfunction

" 2) 读取剪贴板 → 粘贴到光标行下
function! s:ClipPasteBelow() abort
  call append(line('.'), s:ClipGetLines())
endfunction
command! ClipPasteBelow call s:ClipPasteBelow()

" 3) 整个缓冲区 → 剪贴板（单参数方式）
function! s:ClipWriteBuffer() abort
  let l:text = join(getline(1, '$'), "\n")
  " 是否补一个末尾换行，看你需求；如果希望保留“行块语义”，放开下一行：
  " let l:text .= "\n"
  call s:ClipSetArg(l:text)
  echom "[clip] 已将整个缓冲区写入剪贴板"
endfunction
command! ClipWriteBuffer call s:ClipWriteBuffer()

" 4) 指定寄存器 → 剪贴板（单参数方式）
function! s:ClipWriteReg(regname) abort
  if empty(a:regname)
    echohl ErrorMsg | echom "[clip] 需要寄存器名，如 :ClipWriteReg a" | echohl None
    return
  endif
  let l:text = getreg(a:regname)
  " 如需确保末尾换行（行寄存器常见），可按需启用：
  " if l:text !~# '\n$' | let l:text .= "\n" | endif
  call s:ClipSetArg(l:text)
  echom "[clip] 已将寄存器 '" . a:regname . "' 写入剪贴板"
endfunction
command! -nargs=1 ClipWriteReg call s:ClipWriteReg(<f-args>)

" 5) 字符可视选区 → 剪贴板（单参数方式）
function! s:ClipWriteVisualChar() range abort
  let [sline, scol] = [getpos("'<")[1], getpos("'<")[2]]
  let [eline, ecol] = [getpos("'>")[1], getpos("'>")[2]]
  if eline < sline || (eline == sline && ecol < scol)
    let [sline, eline] = [eline, sline]
    let [scol, ecol]   = [ecol,  scol]
  endif
  let lines = getline(sline, eline)
  if empty(lines)
    echom "[clip] 选区为空" | return
  endif
  if len(lines) == 1
    let sel = strpart(lines[0], scol - 1, ecol - scol + 1)
  else
    let first  = strpart(lines[0], scol - 1)
    let last   = strpart(lines[-1], 0, ecol)
    let middle = (len(lines) > 2) ? lines[1:-2] : []
    let sel    = join([first] + middle + [last], "\n")
  endif
  " 如需补末尾换行可自行打开：
  " let sel .= "\n"
  call s:ClipSetArg(sel)
  echom "[clip] 已将字符可视选区写入剪贴板"
endfunction
command! -range ClipWriteVisual call s:ClipWriteVisualChar()

" —— 可选映射 ——（可删）
xnoremap <silent> <leader>cc :<C-U>ClipWriteVisual<CR>
