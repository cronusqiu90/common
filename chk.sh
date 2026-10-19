#!/bin/bash
set -u

# ==================== 默认配置（可用命令行覆盖） ====================
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

MODE="rsync"                    # rsync | rclone

# ==================== 工具函数 ====================
fmt_duration() {
  local total=$1
  local h=$((total / 3600))
  local m=$(((total % 3600) / 60))
  local s=$((total % 60))
  if [ "$h" -gt 0 ]; then
    printf "%dh %dm %ds" "$h" "$m" "$s"
  elif [ "$m" -gt 0 ]; then
    printf "%dm %ds" "$m" "$s"
  else
    printf "%ds" "$s"
  fi
}

fmt_rate() {
  local bytes=$1
  local secs=$2
  if [ "$secs" -le 0 ] || [ "$bytes" -le 0 ]; then
    echo "N/A"
    return
  fi
  awk -v b="$bytes" -v s="$secs" 'BEGIN {
    r = b / s
    if (r >= 1024*1024) {
      printf "%.2f MB/s", r/1024/1024
    } else if (r >= 1024) {
      printf "%.2f KB/s", r/1024
    } else {
      printf "%.2f B/s", r
    }
  }'
}

# ==================== 排除规则 ====================
# tar/rsync 语法（共用）
EXCLUDES=(
  #'*/venv/*'
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
  '.env'
  '*.log'
  '*.tmp'
  '*.pid'
  '*.pyc'
  '*.data'
  '*.dat'
  '*.zip'
  '*.gz'
)


# ==================== 收集存在的目录 ====================
EXIST_ABS=()
echo ">>> 检查目录..."
for d in "${DIRS[@]}"; do
  if [ -d "${HOME_DIR}/${d}" ]; then
    EXIST_ABS+=("${HOME_DIR}/${d}")
    echo "  ✅ 存在: ${HOME_DIR}/${d}"
  else
    echo "  ⚠️  跳过（不存在）: ${HOME_DIR}/${d}"
  fi
done

if [ ${#EXIST_ABS[@]} -eq 0 ]; then
  echo "❌ 没有任何目录存在，退出"
  [ "$MODE" = "rsync" ] && unset SSHPASS
  exit 1
fi

echo
echo ">>> 将同步以下目录:"
printf '    %s\n' "${EXIST_ABS[@]}"
echo

# ==================== 阶段0：估算原始大小 ====================
echo ">>> 阶段0：估算原始大小..."
T0_START=$(date +%s)

TOTAL_BYTES=$(du -s --block-size=1 -- "${EXIST_ABS[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024/1024}')

T0_END=$(date +%s)
T0_COST=$((T0_END - T0_START))

echo "    原始总大小: ${TOTAL_MB} GB"
echo "    阶段0耗时: $(fmt_duration $T0_COST)"
echo
