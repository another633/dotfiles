# 系统模块

每个可执行的 `NAME.sh` 脚本只接收一个参数：`check` 或 `apply`。

- `check` 必须只读，且禁止调用 `sudo`。
- `apply` 必须幂等，并且只能修改文档明确声明的路径或服务。
- 需要使用 `run_sudo` 或 `backup_file` 时，引入 `lib/core.sh`。
- 替换已有系统文件前，调用 `backup_file /明确/路径`。
