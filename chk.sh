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

EXIST_ABS=()
for d in "${DIRS[@]}"; do
  if [ ! -d "${HOME_DIR}/${d}" ]; then
    echo "  ⚠️  跳过（不存在）: ${HOME_DIR}/${d}"
    continue
  fi
  EXIST_ABS+=("${HOME_DIR}/${d}")
done

if [ ${#EXIST_ABS[@]} -eq 0 ]; then
  echo "❌ 没有任何目录存在，退出"
  [ "$MODE" = "rsync" ] && unset SSHPASS
  exit 1
fi

T0_START=$(date +%s)
TOTAL_BYTES=$(du -s --block-size=1 -- "${EXIST_ABS[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024/1024}')
T0_END=$(date +%s)
T0_COST=$((T0_END - T0_START))

echo "Total: ${TOTAL_MB} GB. Duration: $(fmt_duration $T0_COST)"
