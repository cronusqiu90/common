# common

Linux 主机运维脚本与配置合集。按功能模块划分目录，一个模块一个目录；脚本按实际用途命名。

## 模块索引

| 模块 | 用途 | 主要内容 |
| --- | --- | --- |
| `apps/translate/` | 业务应用 | `translate_worker.py`：Celery 翻译任务 worker |
| `backup/` | 同步备份与容量估算 | `sync_home.sh`：rsync/rclone 同步 `/home/auser`；`estimate_home_size.sh`：统计待备份目录体积；`estimate_zstd_size.sh`：估算 zstd 压缩后体积 |
| `cleanup/` | 日志与磁盘清理 | `archive_logs.sh`：归档历史日志；`cleanup_logs.sh`、`cleanup_old_files.sh`、`cleanup_large_logs.py`：清理日志与过期文件；`cleanup_host.sh`：卸载阿里云 agent、删除测试用户并清理业务日志 |
| `database/` | MySQL 安装与表维护 | `install_mysql.sh`、`my.cnf`、Ansible playbook；`fix_im_task_columns.sh`：修正 `im_task` 字段；`recreate_table.sh`：按参数重建表；`recreate_task_table.sh`：重建 `task` 表；`recreate_trigger.sh`：重建 `crawlab_task_trigger` 触发器 |
| `monitoring/` | 监控采集 | Telegraf 配置、systemd unit、Ansible 安装 playbook |
| `resource/` | 进程资源限制 | `limit_process_cpu.sh`：限制业务进程 CPU；`limit_mysql_cpu.sh`：限制 MySQL CPU |
| `security/` | 主机安全加固 | `sshd_config`、`fail2ban/`；`ban_ip.sh`：封禁登录失败 IP；`firewall_port.sh`：端口放行/关闭；`add_user.sh`：创建随机密码用户；`repair_selinux.sh`：修复 SELinux |
| `software/` | 运行环境安装 | `install_python37.sh`、`install_python310.sh`、`install_chrome.sh`、`install_ffmpeg.sh`、`install_xfce_x2go.sh` |
| `supervisor/` | 进程守护 | `supervisord.conf`、`supervisord.service`；`supervisor_prog.py`：supervisord 程序配置的增删改查与格式化 |
| `system/` | 系统配置与维护 | `yum/`：yum 源配置；`vimrc`、`vscode_setting.json`；`show_mem_disk.sh`：查看可用内存与磁盘；`ensure_swap.sh`：无 swap 时创建；`uninstall_aliyun_services.sh`：卸载阿里云助手服务 |

## 命名约定

- Shell 脚本按内容概括命名，统一使用 `.sh` 后缀。
- Python 脚本统一使用 `.py` 后缀。
- 目录名使用小写英文，一个目录对应一个功能模块。

## 注意事项

- 脚本中的 `/home/auser`、端口、数据库名等均为目标主机实际值，复用前先核对。
- `cleanup_host.sh`、`cleanup_logs.sh`、`cleanup_old_files.sh` 含删除操作，执行前务必确认路径。
- `security/ban_ip_dup.sh` 与 `ban_ip.sh` 内容完全相同，属重复副本，待确认后删除。
