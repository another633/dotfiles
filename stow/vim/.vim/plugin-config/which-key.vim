"vim-which-key
let g:mapleader = ','

let g:which_key_map = {}

let g:which_key_map.n = [':NERDTreeToggle', 'NERDTree']
" make
let g:which_key_map.m = [':w | !cmake --build build', 'make']
let g:which_key_map.r = [':call Run_()', 'run']
let g:which_key_map.p = [':ClipPasteBelow', 'clip paste']
" ShowDocumentation is a function defined in coc.vim
let g:which_key_map.h = [':call ShowDocumentation()', 'ShowDocumentation']
let g:which_key_map.s = [':call PinyinSearch()', 'PinyinSearch']

"fzf
let g:which_key_map['f'] = {
			\ 'name' : 'fzf' ,
			\ 'f' : [':Files', 'find files'] ,
			\ 'r' : [':Rg', 'ripgrep'] ,
			\ }
let g:which_key_map['c'] = {
			\ 'name' : 'cmake and coc' ,
			\ 'c' : [':!cmake ..', 'Cmake'] ,
			\ 'r' : [':CocRestart', 'Coc Restart'] ,
			\ }
" tagbar
let g:which_key_map['t'] = {
			\ 'name' : 'terminal and tagbar' ,
			\ 'b' : [':TagbarToggle', 'Tagber'] ,
			\ 't' : [':FloatermToggle', 'terminal'] ,
			\ 'd' : [':call T#Main(expand("<cword>"))', 'dict'],
			\ }

let g:which_key_map['d'] = {
			\ 'name' : 'debug' ,
			\ 'd' : [':call Debug()', 'debug'] ,
			\ 'c' : [':call DebugCommand()', 'debug command'] ,
			\ 'e' : [':DictToggle', '词典'] ,
			\ }

let g:which_key_map_visual = {}

let g:which_key_map_visual.y = [':ClipWriteVisual', 'copy to android clipboard']

call which_key#register('<Space>', "g:which_key_map", 'n')
call which_key#register('<Space>', "g:which_key_map_visual", 'v')

nnoremap <silent> <Space> :<c-u>WhichKey '<Space>'<CR>
vnoremap <silent> <Space> :<c-u>WhichKeyVisual  '<Space>'<CR>
