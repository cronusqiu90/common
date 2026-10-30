#!/bin/bash
# 后台静默压缩脚本：生成 {hostname}.tar.zst
# 用法: nohup ./compress_zstd.sh [输出目录] &

set -euo pipefail

##################### 配置区 #####################
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

ZSTD_LEVEL=10
ZSTD_THREADS=0

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

OUTPUT_DIR="/home/auser"
HOSTNAME=$(hostname)
FINAL_FILE="${OUTPUT_DIR}/${HOSTNAME}.tar.zst"
TMP_FILE="${FINAL_FILE}.tmp"
LOG_FILE="/tmp/pkg.log"
##################### 配置区 #####################

rm -rf "${TMP_FILE}"
rm -rf "${FINAL_FILE}"
rm -rf "${LOG_FILE}"

# 重定向所有输出到日志文件
exec > "${LOG_FILE}" 2>&1

# 依赖检查
command -v zstd >/dev/null 2>&1 || { echo "ERROR: 缺少 zstd"; exit 1; }
[ -d "$HOME_DIR" ] || { echo "ERROR: HOME_DIR 不存在: $HOME_DIR"; exit 1; }
[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"

# 清理函数
cleanup() {
    if [ -f "$TMP_FILE" ]; then
        rm -f "$TMP_FILE"
        echo "CLEANUP: 已删除临时文件 ${TMP_FILE}"
    fi
}
trap cleanup EXIT

# 构造 exclude 参数
EXCLUDE_ARGS=()
for p in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$p")
done

# 过滤存在的目录
EXIST_DIRS=()
for d in "${DIRS[@]}"; do
    if [ -d "${HOME_DIR}/${d}" ]; then
        EXIST_DIRS+=("$d")
    else
        echo "WARN: 跳过不存在目录 ${HOME_DIR}/${d}"
    fi
done

if [ ${#EXIST_DIRS[@]} -eq 0 ]; then
    echo "ERROR: 无可压缩目录"
    exit 1
fi

cd "$HOME_DIR"

echo "START: $(date)"
echo "TARGET: ${FINAL_FILE}"
echo "DIRS: ${EXIST_DIRS[*]}"

START_TIME=$(date +%s)

# 执行压缩
tar \
    --warning=no-file-changed \
    --ignore-failed-read \
    "${EXCLUDE_ARGS[@]}" \
    -cf - \
    "${EXIST_DIRS[@]}" \
| zstd -"${ZSTD_LEVEL}" -T"${ZSTD_THREADS}" -o "${TMP_FILE}"

# 成功则重命名
mv "${TMP_FILE}" "${FINAL_FILE}"
trap - EXIT

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
SIZE_BYTES=$(stat -c%s "${FINAL_FILE}" 2>/dev/null || stat -f%z "${FINAL_FILE}" 2>/dev/null)

human() {
    awk -v b="$1" 'BEGIN{
        split("B KB MB GB TB", u, " ");
        i=1; while (b>=1024 && i<5){ b/=1024; i++ }
        printf "%.2f %s", b, u[i]
    }'
}

echo "SUCCESS"
echo "FILE: ${FINAL_FILE}"
echo "SIZE: ${SIZE_BYTES} bytes ($(human "$SIZE_BYTES"))"
echo "DURATION: ${DURATION}s"
echo "END: $(date)"

exit 0
