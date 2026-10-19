#!/bin/bash
set -u

# ==================== 默认配置（可用命令行覆盖） ====================
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

MODE="rsync"                    # rsync | rclone

# 目标机（rsync 用）
TARGET_USER="auser"
TARGET_HOST="$1"
TARGET_PASS="$2"
TARGET_PORT=8513
TARGET_BASE="/"

# rclone remote 名称（rclone 用）
RCLONE_REMOTE="aa"

# rclone 参数
RCLONE_TRANSFERS=16
RCLONE_MULTI_THREAD=4
RCLONE_CHECKERS=32

# 是否跳过阶段1（测大小）
SKIP_SIZE_TEST=1

# 日志
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
  '*.part_*'
  '*.task'
)

# rclone 语法（*/xxx/* -> **/xxx/**）
RCLONE_EXCLUDES=(
  '.env'
  '*.log'        # ← 关键改动
  '*.tmp'        # ← 同样问题
  '*.pid'        # ← 同样问题
  '*.pyc'        # ← 同样问题
  '*.data'       # ← 同样问题
  '*.dat'        # ← 同样问题
  '*.zip'        # ← 同样问题
  '*.gz'         # ← 同样问题
  #'**/venv/**'
  '**/.venv/**'
  '**/logs/**'
  '**/tmp/**'
  '**/__pycache__/**'
  '**/.git/**'
  '**/node_modules/**'
  '**/.idea/**'
  '**/.vscode/**'
  '**/tempDownload/**'
  '**/tempData/**'
  '**/testCode/**'
  '**/Temp/**'
  '**/temp/**'
)

# ==================== 模式相关检查 ====================
echo ">>> 传输模式: ${MODE}"
echo

if [ "$MODE" = "rsync" ]; then
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "❌ 未安装 sshpass，请先: yum install sshpass -y"
    exit 1
  fi

  echo ">>> 检查目标机是否安装 rsync..."

  if ! sshpass -p "${TARGET_PASS}" ssh -p "${TARGET_PORT}" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout=10 \
      "${TARGET_USER}@${TARGET_HOST}" \
      "command -v rsync >/dev/null 2>&1"; then
    echo "❌ 目标机未安装 rsync，请先: yum install rsync -y"
    unset SSHPASS
    exit 1
  fi
  echo "    ✅ 目标机 rsync 可用"
  echo
else
  if ! command -v rclone >/dev/null 2>&1; then
    echo "❌ 未安装 rclone，请先: curl https://rclone.org/install.sh | bash"
    exit 1
  fi

  if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:$"; then
    echo "❌ rclone remote '${RCLONE_REMOTE}' 未配置"
    echo "   请先执行: rclone config"
    exit 1
  fi
  echo "    ✅ rclone remote '${RCLONE_REMOTE}' 可用"
  echo
fi

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

TOTAL_BYTES=$(du -sb "${EXIST_ABS[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024}')

T0_END=$(date +%s)
T0_COST=$((T0_END - T0_START))

echo "    原始总大小: ${TOTAL_MB} MB"
echo "    阶段0耗时: $(fmt_duration $T0_COST)"
echo

# ==================== 阶段1：测压缩后大小（可选） ====================
T1_COST=0
SIZE_BYTES=0
if [ "$SKIP_SIZE_TEST" -eq 0 ]; then
  echo ">>> 阶段1：测试压缩后大小（不落盘，会完整读一遍数据）..."
  T1_START=$(date +%s)

  TAR_EXCLUDE_ARGS=()
  for pat in "${EXCLUDES[@]}"; do
    TAR_EXCLUDE_ARGS+=(--exclude="$pat")
  done

  REL_DIRS=()
  for d in "${DIRS[@]}"; do
    [ -d "${HOME_DIR}/${d}" ] && REL_DIRS+=("home/auser/${d}")
  done

  if command -v zstd >/dev/null 2>&1; then
    SIZE_BYTES=$(tar -cf - -C / "${TAR_EXCLUDE_ARGS[@]}" "${REL_DIRS[@]}" 2>/dev/null \
      | zstd -T4 -1 \
      | wc -c)
  else
    echo "    ⚠️  源端未装 zstd，阶段1跳过"
    SIZE_BYTES=0
  fi

  if [ "$SIZE_BYTES" -gt 0 ]; then
    SIZE_MB=$(awk -v b="$SIZE_BYTES" 'BEGIN {printf "%.2f", b/1024/1024}')
    echo "    压缩后大小: ${SIZE_MB} MB (${SIZE_BYTES} 字节)"
  fi

  T1_END=$(date +%s)
  T1_COST=$((T1_END - T1_START))

  echo "    阶段1耗时: $(fmt_duration $T1_COST)"
  echo

  echo ">>> 磁盘可用空间:"
  df -h /tmp | tail -1
  echo
else
  echo ">>> 已跳过阶段1（--skip-size-test）"
  echo
fi

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

  # -rlpgoDz：归档但去掉 t（避免改目录时间戳报 Operation not permitted）
  # -O：不修改目录时间戳
  # --partial：断点续传
  # -q：静默，只输出错误
  # -R：保留相对路径，配合目标 / 还原绝对路径
  sshpass -p "${TARGET_PASS}" rsync -rlpgoDz --partial -q -R -O \
    -e "ssh -p ${TARGET_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "${RSYNC_EXCLUDE_ARGS[@]}" \
    "${EXIST_ABS[@]}" \
    "${TARGET_USER}@${TARGET_HOST}:${TARGET_BASE}" \
    2>>"$RSYNC_ERR_LOG"

  RC=$?
  unset SSHPASS

  if [ -s "$RSYNC_ERR_LOG" ]; then
    echo "⚠️  rsync 错误/警告："
    cat "$RSYNC_ERR_LOG"
    echo
  fi

else
  # ---------- rclone 模式 ----------
  echo ">>> 阶段2：rclone 传输到 ${RCLONE_REMOTE} ..."
  echo

  RCLONE_EXCLUDE_ARGS=()
  for pat in "${RCLONE_EXCLUDES[@]}"; do
    RCLONE_EXCLUDE_ARGS+=(--exclude "$pat")
  done

  echo ">>> rclone 排除参数: ${RCLONE_EXCLUDE_ARGS[*]}"

  : > "$RCLONE_ERR_LOG"

  for d in "${DIRS[@]}"; do
    SRC="${HOME_DIR}/${d}"
    [ -d "$SRC" ] || continue

    echo ">>> 同步 ${d} ..."

    rclone copy "$SRC" "${RCLONE_REMOTE}:/home/auser/${d}" \
      --transfers="${RCLONE_TRANSFERS}" \
      --multi-thread-streams="${RCLONE_MULTI_THREAD}" \
      --checkers="${RCLONE_CHECKERS}" \
      "${RCLONE_EXCLUDE_ARGS[@]}" \
      -v \
      --stats-one-line

    RC=$?
    if [ $RC -ne 0 ]; then
      echo "❌ ${d} 同步失败（退出码 ${RC}）"
      break
    fi
    echo "    ✅ ${d} 完成"
    echo
  done

  if [ -s "$RCLONE_ERR_LOG" ]; then
    echo "⚠️  rclone 错误/警告："
    cat "$RCLONE_ERR_LOG"
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
echo "  阶段0（估算原始大小）: $(fmt_duration $T0_COST)"
if [ "$SKIP_SIZE_TEST" -eq 0 ]; then
  echo "  阶段1（测压缩后大小）: $(fmt_duration $T1_COST)"
else
  echo "  阶段1（测压缩后大小）: 已跳过"
fi
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
