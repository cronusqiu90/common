#!/bin/bash


set -u

# ==================== 默认配置（可用命令行覆盖） ====================
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

MODE="rsync"  

# 目标机（rsync 用）
TARGET_USER="auser"
TARGET_HOST="$1"
TARGET_PASS="$2"
TARGET_PORT=8513
TARGET_BASE="/home/auser"
RSYNC_ERR_LOG="/tmp/rsync_error.log"
RCLONE_ERR_LOG="/tmp/rclone_error.log"


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

# ==================== 阶段1：估算原始大小 ====================
echo ">>> 阶段1：估算原始大小..."
T0_START=$(date +%s)

TOTAL_BYTES=$(du -sb "${EXIST_ABS[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024}')

T0_END=$(date +%s)
T0_COST=$((T0_END - T0_START))

echo "    原始总大小: ${TOTAL_MB} MB"
echo "    阶段1耗时: $(fmt_duration $T0_COST)"
echo

# ==================== 阶段2：传输 ====================
T2_START=$(date +%s)
RC=0

if [ "$MODE" = "rsync" ]; then
  # ---------- rsync 模式 ----------
  echo ">>> 阶段2：rsync 传输到 ${TARGET_USER}@${TARGET_HOST} ..."
  echo

  RSYNC_EXCLUDE_ARGS=()
  for pat in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDE_ARGS+=(--exclude="$pat")
  done

  : > "$RSYNC_ERR_LOG"
  sshpass -p '${TARGET_PASS}' rsync -rlpgoDz --partial -q -R -O \
    -e "ssh -p ${TARGET_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "${RSYNC_EXCLUDE_ARGS[@]}" \
    "${EXIST_ABS[@]}" \
    "${TARGET_USER}@${TARGET_HOST}:${TARGET_BASE}" \
    2>>"$RSYNC_ERR_LOG"

  RC=$?

  if [ -s "$RSYNC_ERR_LOG" ]; then
    echo "⚠️  rsync 错误/警告："
    cat "$RSYNC_ERR_LOG"
    echo
  fi

fi

T2_END=$(date +%s)
T2_COST=$((T2_END - T2_START))

echo

# ==================== 汇总 ====================
TOTAL_COST=$((T0_COST + T1_COST + T2_COST))

RATE_RAW=$(fmt_rate "$TOTAL_BYTES" "$T2_COST")
if [ "$SIZE_BYTES" -gt 0 ]; then
  RATE_COMP=$(fmt_rate "$SIZE_BYTES" "$T2_COST")
else
  RATE_COMP="N/A（阶段1已跳过）"
fi

echo "================================"
echo "传输模式: ${MODE}"
echo "耗时汇总"
echo "  阶段1（估算原始大小）: $(fmt_duration $T0_COST)"
echo "  阶段2（传输）:         $(fmt_duration $T2_COST)"
echo "  ------------------------------"
echo "  总计:                  $(fmt_duration $TOTAL_COST)"
echo
echo "传输速率"
echo "  原始数据速率:   ${RATE_RAW}   （原始 ${TOTAL_MB} MB / 阶段2耗时）"
echo "  压缩后速率:     ${RATE_COMP}"
echo "================================"
echo

if [ $RC -eq 0 ] || [ $RC -eq 23 ]; then
  echo "✅ 传输完成（或部分属性未同步，不影响文件, 退出码 ${RC}）"
else
  echo "❌ 传输失败（退出码 ${RC}）"
  exit 1
fi
