# Dotfiles 框架说明

本文档说明项目的整体架构、执行流程、Profile 组织方式和扩展规则。

## 设计目标

- 只面向 Debian 11 及以上版本。
- 用 GNU Stow 管理用户配置，不复制或强制覆盖原文件。
- 用 Profile 组合机器角色，避免把所有软件写在一个安装脚本中。
- 用幂等模块处理源码构建、二进制安装和需要权限的系统操作。
- `check` 始终只读，`apply` 仅修复未满足的目标状态。

## 项目结构

```text
dot                         # 命令行入口
lib/
  core.sh                   # 日志、sudo、代理、备份等通用函数
  profiles.sh               # Profile 依赖解析和 Manifest 合并
  actions.sh                # check/apply/bootstrap/unstow 执行流程
  github-release.sh         # GitHub Release 下载、校验和解包
profiles/{base,dev,desktop}/ # 机器角色的声明式清单
stow/<package>/             # 映射到 $HOME 的用户配置
modules/source/             # 不使用 sudo 的用户级安装模块
modules/system/             # 可修改明确系统路径的特权模块
tests/                      # 便携回归测试和 Bats 测试
```

## 命令与生命周期

| 命令 | 作用 |
| --- | --- |
| `./dot list` | 显示可用 Profile 和当前机器已保存的 Profile |
| `./dot check --profile base` | 只读检查软件、Stow 冲突和模块状态 |
| `./dot apply --profile base` | 安装缺失项并部署配置，不保存 Profile 选择 |
| `./dot bootstrap --profile base` | 首次安装、应用并保存 Profile 选择 |
| `./dot unstow --profile base` | 只删除 Stow 链接，不卸载软件或回滚系统模块 |

未显式指定 Profile 时，命令从
`${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profiles` 读取已保存选择。
首次运行 `bootstrap` 且没有保存文件时，默认选择 `base dev desktop`。

`apply` 的顺序为：

```text
Debian 检查 → 代理预检 → APT → Stow 冲突预检 → Flatpak
           → mise → Stow → 用户级模块 → 系统模块
```

任意 Stow 包有冲突时，所有 Stow 操作在开始前终止，避免机器处于部分链接状态。

## Profile 组织

Profile 位于 `profiles/<name>/`，通过 `deps` 形成依赖图。解析器会先加载依赖，
检测循环依赖，并在合并后去重。

| Profile | 用途 | 主要内容 |
| --- | --- | --- |
| `base` | 所有机器的基础环境 | Git、Stow、Curl、Fzf、Ripgrep、Jq、Tmux、Zsh、Oh My Zsh、个人配置和脚本 |
| `dev` | 开发工作站，依赖 `base` | GCC/G++、Clang/clangd、CMake、Lua/Python 开发库、Node、Rust、.NET 10、Vim 和 CLI 工具 |
| `desktop` | Sway 桌面，依赖 `base` | Sway、Foot、Fcitx5、截图/录屏依赖、Wob、i3status、Nerd Font、Chrome 和 Zen Browser |

每个 Profile 可包含以下逐行 Manifest：

| 文件 | 每行格式 | 执行方式 |
| --- | --- | --- |
| `deps` | Profile 名 | 递归解析依赖 |
| `apt` | Debian 包名 | `apt-get install --no-install-recommends` |
| `flatpak` | Application ID | 用户级 Flathub 安装 |
| `mise` | `<tool> <version>` | `mise use --global` |
| `stow` | `stow/` 下的目录名 | 链接到 `$HOME` |
| `source` | `modules/source/NAME.sh` 中的 `NAME` | 用户级模块 |
| `system` | `modules/system/NAME.sh` 中的 `NAME` | 特权系统模块 |

Manifest 支持空行和 `#` 注释。名称必须符合
`[a-z0-9][a-z0-9_-]*`；`mise` 条目必须恰好包含工具名和版本。

## Stow 配置层

`stow/<package>/` 内的路径完整映射 `$HOME`。例如：

```text
stow/git/.gitconfig                 → ~/.gitconfig
stow/zsh/.zshrc                     → ~/.zshrc
stow/sway/.config/sway/config       → ~/.config/sway/config
stow/scripts/.local/bin/clash       → ~/.local/bin/clash
```

所有 Stow 操作都使用 `--no-folding`，因此只链接文件，不把整个父目录变成链接。
`*.swp` 始终被忽略。普通文件或指向其他仓库的旧链接会被视为冲突，框架不会覆盖。

## 安装模块

用户级和系统模块都是可执行 Bash 脚本，只接受 `check` 或 `apply`：

- `check` 必须只读、不访问网络、不调用 `sudo`。
- `apply` 必须幂等，目标已满足时直接返回。
- `modules/source/` 安装到 `~/.local`，不得调用 `sudo`。
- `modules/system/` 只能修改文档明确声明的路径，替换系统文件前通过 `backup_file` 备份。

当前用户级模块：

- Vim：固定 tag/commit 源码编译，开启 Lua、Python 3、Perl、X11/Wayland 剪贴板，
  禁用 GUI、Ruby 和 Tcl；安装到 `~/.local/opt/vim/`，并安装 vim-plug。
- AIChat、Bookokrat、Yazi、Ttyper：下载固定 GitHub Release 二进制并校验 SHA-256。
- Oh My Zsh：下载固定官方提交，通过 `current` 链接激活。
- Hack Nerd Font 和 Zen Browser：下载固定官方资产。

当前系统模块：

- Google Chrome：从 Google 官网下载当前 stable DEB，校验包名与架构后安装。
- Mihomo：校验固定版本二进制、部署 systemd 单元、验证配置并启用服务。

## 代理与网络恢复

`bootstrap` 和 `apply` 在首个联网操作前检查代理。交互终端会询问是否配置或
重新配置；非交互环境直接使用当前环境或已保存配置。代理文件位于：

```text
${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local/proxy.env
```

文件和父目录使用私有权限，代理变量会同时传递给普通命令和经 `sudo` 执行的 APT。

## Mihomo 配置管理

真实配置不得提交到仓库。首次安装前将它放在：

```text
~/.config/dotfiles/local/mihomo/config.yaml
```

系统模块验证后将其安装到 `/etc/mihomo/config.yaml`。`clash` 脚本提供：

1. 从 `Proxies` 组选择节点。
2. 开启或关闭 `allow-lan`，并设置 `mixed-port`。默认使用当前端口，无有效值时使用 `7893`。
3. 启动带随机令牌的一次性 Python 上传服务，用 `qrencode` 显示二维码。

上传配置时保留当前运行中的 `allow-lan` 和 `mixed-port`。候选配置必须先通过
Mihomo 验证；替换时创建临时备份，成功后删除，启动失败时恢复后删除。

可选环境变量：

- `MIHOMO_API`：默认 `http://127.0.0.1:9090`。
- `MIHOMO_SECRET`：REST API Bearer token。
- `MIHOMO_PROXY_GROUP`：默认 `Proxies`。

## 本机私有状态

以下内容均在仓库外：

| 路径 | 用途 |
| --- | --- |
| `~/.config/dotfiles/profiles` | `bootstrap` 保存的 Profile |
| `~/.config/dotfiles/local/proxy.env` | 安装期间的代理环境 |
| `~/.config/dotfiles/local/mihomo/config.yaml` | Mihomo 私有配置 |
| `~/.config/dotfiles/local/gitconfig` | Git 本机或私有配置 |
| `~/.config/dotfiles/local/zshrc` | Zsh 本机或私有配置 |
| `~/.cache/dotfiles/` | 构建和下载缓存 |

这些文件可能包含凭据、订阅地址或机器差异，不应复制到 `stow/` 或提交到 Git。

## 扩展框架

### 添加 APT、Flatpak 或 mise 工具

在目标 Profile 的对应 Manifest 中添加一行。例如：

```text
# profiles/dev/mise
go 1.25
```

### 添加 Stow 包

1. 在 `stow/<package>/` 中按 `$HOME` 相对路径放置文件。
2. 将 `<package>` 加入目标 Profile 的 `stow` Manifest。
3. 先运行 `./dot check --profile <name>` 检查冲突。

### 添加模块

1. 创建可执行的 `modules/source/NAME.sh` 或 `modules/system/NAME.sh`。
2. 实现只读 `check` 和幂等 `apply`。
3. 为下载资产固定版本和 SHA-256，并支持 Debian `amd64`/`arm64` 映射。
4. 将模块名加入 Profile 的 `source` 或 `system` Manifest。
5. 在 `tests/run.sh` 增加快速回归测试。

## 测试与提交前检查

```sh
./tests/run.sh
bats tests/dot.bats
shellcheck dot lib/*.sh modules/source/*.sh modules/system/*.sh tests/*.sh
bash -n dot lib/*.sh modules/source/*.sh modules/system/*.sh tests/run.sh
git diff --check
```

`tests/run.sh` 不依赖 Bats，适合在刚恢复的机器上执行。测试不得运行
`bootstrap`、`apply` 或 `unstow`，应使用临时 `HOME` 和命令桩验证写入逻辑。

## 常见问题

### Stow 一个链接都没有创建

查看 `check` 输出中的 `Stow conflict`。框架会在任何一个包冲突时中止全部链接。
先备份或移走目标中的旧文件/旧链接，然后重新执行 `apply`。

### Vim 版本或功能验证失败

验证使用 `LC_ALL=C` 固定输出语言，避免 gettext 将版本描述翻译后导致误判。
若仍失败，直接查看 `~/.local/opt/vim/<version>/bin/vim --version` 的缺失功能。

### 非交互安装没有代理提示

这是预期行为。非交互环境不等待输入，请预先设置代理环境变量或创建
`~/.config/dotfiles/local/proxy.env`。
