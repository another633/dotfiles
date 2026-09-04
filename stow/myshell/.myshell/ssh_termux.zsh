#/usr/bin/zsh

REPO=""

_open_repo() {
	REPO=$(gh repo list | cut -f1 | fzf)

	if [ -z "$REPO" ]; then
		exit 1
	else
		openurl "https://github.com/$REPO"
	fi
}

mygh() {
	while getopts ":l" opt; do
			case "$opt" in
					l) _open_repo; exit 0 ;;
					*) echo "用法: $0 -l"; exit 1 ;;
			esac
	done

	if [ -z "$1" ]; then
		openurl "https://github.com/another633?tab=repositories"
	else
		openurl "https://github.com/another633/$1"
	fi
}
