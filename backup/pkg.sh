#!/bin/bash
# 计算 zstd 压缩后大小并生成 .zst 文件
# 用法: ./compress_zstd.sh [输出目录]

set -euo pipefail

##################### 配置区 #####################
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

ZSTD_LEVEL=10
ZSTD_THREADS=0          # 0 = 用满所有 CPU

EXCLUDES=(
  '*/venv/*'
  '*/.venv/*'
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

# 输出目录（默认当前目录）
OUTPUT_DIR="${1:-.}"
HOSTNAME=$(hostname)
DATE=$(date +%Y%m%d)
OUTPUT_FILE="${OUTPUT_DIR}/${HOSTNAME}.tar.zst"
##################### 配置区 #####################

# 依赖检查
command -v zstd >/dev/null 2>&1 || { echo "缺少 zstd，请: yum install -y zstd" >&2; exit 1; }
[ -d "$HOME_DIR" ] || { echo "HOME_DIR 不存在: $HOME_DIR" >&2; exit 1; }
[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"

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

echo "开始压缩..."
echo "目标: ${OUTPUT_FILE}"
echo "目录: ${EXIST_DIRS[*]}"

START_TIME=$(date +%s)

# tar → zstd 直接输出到文件
tar \
    --warning=no-file-changed \
    --ignore-failed-read \
    "${EXCLUDE_ARGS[@]}" \
    -cf - \
    "${EXIST_DIRS[@]}" \
| zstd -"${ZSTD_LEVEL}" -T"${ZSTD_THREADS}" -o "${OUTPUT_FILE}"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 获取文件大小
SIZE_BYTES=$(stat -c%s "${OUTPUT_FILE}" 2>/dev/null || stat -f%z "${OUTPUT_FILE}" 2>/dev/null)

# 人类可读格式
human() {
    awk -v b="$1" 'BEGIN{
        split("B KB MB GB TB", u, " ");
        i=1; while (b>=1024 && i<5){ b/=1024; i++ }
        printf "%.2f %s", b, u[i]
    }'
}

echo "完成!"
echo "文件: ${OUTPUT_FILE}"
echo "大小: ${SIZE_BYTES} bytes ($(human "$SIZE_BYTES"))"
echo "耗时: ${DURATION} 秒"

exit 0
