"nerdtree
nnoremap <C-n> :NERDTreeToggle<CR>
"禁用光标键
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>

"关闭选区高亮快捷映射
nnoremap<silent> <C-l> :<C-u>nohlsearch<CR><C-l>

"展开当前文件所在的目录
cnoremap <expr> %% getcmdtype() == ':' ? expand( '%:h' ).'/' : '%%'

"vim-easymotion-------------------------------------------------------------------------------------------
" <Leader>f{char} to move to {char}
noremap  <Leader>f <Plug>(easymotion-bd-f)
nnoremap <Leader>f <Plug>(easymotion-overwin-f)

" s{char}{char} to move to {char}{char}
nnoremap <Leader>s <Plug>(easymotion-overwin-f2)

" Move to line
noremap <Leader>l <Plug>(easymotion-bd-jk)
nnoremap <Leader>l <Plug>(easymotion-overwin-line)

" Move to word
noremap  <Leader>w <Plug>(easymotion-bd-w)
nnoremap <Leader>w <Plug>(easymotion-overwin-w)

" Dict.vim-------------------------------------------------------------------------------------------
nnoremap <Leader>k :call ShowDocumentation_zh_CN()<CR>
let g:dict_insert_reverse_map = ''
inoremap <silent> <C-g>; <Plug>(DictInsertReverseComplete)

nnoremap <Leader>e :DictToggle<CR>
xnoremap <Leader>e :<C-U>DictToggle<CR>

"FZF-------------------------------------------------------------------------------------------
nnoremap <Leader>j :Jumps<CR>
nnoremap <Leader>m :Maps<CR>

"Windsurf-------------------------------------------------------------------------------------------
let g:codeium_disable_bindings = 1
inoremap <script><silent><nowait><expr> <Leader><Tab> codeium#Accept()
inoremap <script><silent><nowait><expr> <Leader>w codeium#AcceptNextWord()
inoremap <script><silent><nowait><expr> <Leader>l codeium#AcceptNextLine()

"Aicaht-------------------------------------------------------------------------------------------
nnoremap <Leader>ct :AiChatTerm
vnoremap <Leader>ct :AiChatTerm
nnoremap <Leader>cc :AiChatToggle<CR>
vnoremap <Leader>cc :AiChatToggle<CR>

"Goyo-------------------------------------------------------------------------------------------
nnoremap <silent> <leader>z :Goyo<cr>

"Easy-align-------------------------------------------------------------------------------------------
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)
