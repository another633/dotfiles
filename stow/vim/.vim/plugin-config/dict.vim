let g:dict_db_dir = expand('~/English/NCE/Resource/Dict')
let g:dict_detail_source = 'longman'

let g:dict_detail_backend = 'auto'
let g:dict_detail_c_bin = '/home/liushuan/Projects/vim/Dict.vim/scripts/dict_detail_c/build/bin/dict_detail_c'

let g:dict_word_completion = 0

if executable('aichat')
	let	g:dict_trans_model = 'deepseek:deepseek-v4-flash'
    " let	g:dict_trans_prompt = '你是一位英语教师。请翻译下面的英文，不要扩展多余回答。内容如下：'
    let	g:dict_trans_display = 'virtual'
endif
