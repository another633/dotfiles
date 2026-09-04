# Debian dotfiles

一套面向 Debian 11+ 的轻量 dotfiles 框架：GNU Stow 管理用户配置，Profile
组合软件与功能，显式模块处理少量系统设置。

完整的框架设计、执行顺序、Profile 和扩展规则见
[`docs/framework.md`](docs/framework.md)。

## 快速开始

```sh
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
./dot check --profile base --profile dev --profile desktop
./dot bootstrap --profile base --profile dev --profile desktop
```

`bootstrap` 会保存本机启用的 Profile。之后直接运行：

```sh
./dot check
./dot apply
```

`bootstrap` 和 `apply` 会在联网安装前检查代理环境。交互运行时可选择
配置或重新配置代理，结果保存到
`~/.config/dotfiles/local/proxy.env`，并传递给 APT、Curl、Cargo 等安装命令。
非交互环境不会等待输入，仅使用已有环境变量或保存的配置。

遇到已有普通文件或指向其他来源的符号链接时，命令会停止并报告冲突，不会
覆盖用户数据。所有 Stow 操作都会禁用目录折叠并忽略 Vim 产生的 `*.swp`
交换文件，避免交换文件通过父目录链接间接出现在目标目录。

## 命令

- `./dot bootstrap [--profile NAME ...]`：安装框架依赖、保存 Profile 并应用配置。
- `./dot check [--profile NAME ...]`：只读检查依赖、冲突、软件和系统模块状态。
- `./dot apply [--profile NAME ...]`：安装缺失软件、部署配置并执行系统模块。
- `./dot unstow [--profile NAME ...]`：只删除由 Stow 管理的链接。
- `./dot list`：列出 Profile 以及当前启用项。

没有已保存配置时，`bootstrap` 默认启用 `base dev desktop`；其他需要 Profile 的
命令会要求显式指定。

## 扩展

每个 `profiles/<name>/` 可包含以下逐行清单（空行和 `#` 注释会被忽略）：

- `deps`：依赖的 Profile。
- `stow`：`stow/` 下的包名。
- `apt`：APT 包名。
- `flatpak`：Flatpak application ID。
- `mise`：每行 `tool version`，如 `node lts`。
- `source`：`modules/source/` 下的用户级源码模块名。
- `system`：`modules/system/` 下的模块名。

用户级安装模块是接受 `check` 或 `apply` 的幂等 Bash 脚本。AIChat、
Bookokrat、Yazi 和 Ttyper 使用固定版本与 SHA-256 的 GitHub Release 二进制。
`dev` Profile 默认从
固定源码版本编译 Vim，安装到 `~/.local/opt/vim/`，再通过 `current` 链接暴露到
`~/.local/bin/`。升级 Vim 时同时修改模块中的 tag 和 commit；框架不会自动删除
旧版本，便于手动回滚。Vim 安装后会从官方仓库下载 vim-plug 到
`~/.vim/autoload/plug.vim`。

`base` Profile 安装 Zsh、`zsh-autosuggestions` 和 `zsh-syntax-highlighting`，
并从官方 GitHub 归档安装固定提交的 Oh My Zsh。框架位于
`~/.local/share/oh-my-zsh/current`，不会自动修改用户的登录 shell。

系统模块是可执行 Bash 脚本，接受 `check` 或 `apply`。模块必须保证幂等，只能
对明确目标使用 `sudo`；修改已有系统文件前应通过 `backup_file` 创建一次备份。
`desktop` Profile 从 Google 官网下载 DEB 安装 Chrome，从 Zen Browser 官方
GitHub Release 下载固定版本的 `tar.xz` 安装 Zen Browser。
Mihomo 的真实代理配置不得提交到仓库；新机器应将其放在
`~/.config/dotfiles/local/mihomo/config.yaml`，首次应用时会复制到 `/etc/mihomo/`。
`clash` 提供节点选择、局域网代理配置，以及带随机令牌和二维码的一次性
配置上传服务。配置更新前会先验证并创建临时备份；新配置启动成功后删除备份，
启动失败时恢复原配置后也会删除备份。

本地覆盖文件位于 `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local/`。当前 Git
和 Zsh 配置会自动加载其中的 `gitconfig` 与 `zshrc`；敏感信息不要放进仓库。

## 开发检查

```sh
./tests/run.sh
shellcheck dot lib/*.sh modules/source/*.sh modules/system/*.sh
# 安装 bats 后：bats tests/dot.bats
```
