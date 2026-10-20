#!/bin/bash
# 计算 zstd 压缩后大小，不落地文件
# 用法: ./estimate_zstd_size.sh

set -euo pipefail

##################### 配置区 #####################
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

ZSTD_LEVEL=10
ZSTD_THREADS=0          # 0 = 用满所有 CPU

EXCLUDES=(
  '*/logs/*'
  '*/tmp/*'
  '*/__pycache__/*'
  '*/.git/*'
  '*/node_modules/*'
  '*/.idea/*'
  '*/.vscode/*'
  '*/tempDownload/*'
  '*/tempData/*'
  '*/testCode/*'
  '*/Temp/*'
  '*/temp/*'
  '*.log'
  '*.tmp'
  '*.pid'
  '*.pyc'
  '*.data'
  '*.dat'
  '*.zip'
  '*.gz'
  '*.part_*'
  '*.task'
)
##################### 配置区 #####################

# 依赖检查
command -v zstd >/dev/null 2>&1 || { echo "缺少 zstd，请: yum install -y zstd" >&2; exit 1; }
[ -d "$HOME_DIR" ] || { echo "HOME_DIR 不存在: $HOME_DIR" >&2; exit 1; }

# 构造 exclude 参数
EXCLUDE_ARGS=()
for p in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$p")
done

# 过滤存在的目录
EXIST_DIRS=()
for d in "${DIRS[@]}"; do
    [ -d "${HOME_DIR}/${d}" ] && EXIST_DIRS+=("$d") \
        || echo "警告: 跳过不存在目录 ${HOME_DIR}/${d}" >&2
done
[ ${#EXIST_DIRS[@]} -gt 0 ] || { echo "无可压缩目录" >&2; exit 1; }

cd "$HOME_DIR"

# 关键：tar → zstd → wc -c 全管道，只有字节数输出
# zstd 的 "-c" 表示输出到 stdout；"-q" 抑制统计信息到 stderr
SIZE_BYTES=$(
    tar \
        --warning=no-file-changed \
        --ignore-failed-read \
        "${EXCLUDE_ARGS[@]}" \
        -cf - \
        "${EXIST_DIRS[@]}" \
    | zstd -"${ZSTD_LEVEL}" -T"${ZSTD_THREADS}" -q -c \
    | wc -c
)

# 人类可读格式
human() {
    awk -v b="$1" 'BEGIN{
        split("B KB MB GB TB", u, " ");
        i=1; while (b>=1024 && i<5){ b/=1024; i++ }
        printf "%.2f %s", b, u[i]
    }'
}
echo "${SIZE_BYTES} bytes,  $(human "$SIZE_BYTES")"
exit 0
