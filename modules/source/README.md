# 源码模块

每个可执行的 `NAME.sh` 脚本只接收一个参数：`check` 或 `apply`。

- `check` 必须只读且不得访问网络。
- `apply` 必须幂等；满足目标状态时不得重复构建。
- 用户级软件安装到 `~/.local`，不得调用 `sudo`。
- 下载内容放在 `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/sources/`。
- 覆盖现有文件或链接前必须验证其确实由对应模块管理。
