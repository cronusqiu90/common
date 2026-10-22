#!/bin/bash
set -u

# ==================== 默认配置 ====================
HOME_DIR="/home/auser"
DIRS=(Crawler TRClient Tools supervisord.d etc)

# ==================== 工具函数 ====================
fmt_duration() {
  local total=$1
  local h=$((total / 3600))
  local m=$(((total % 3600) / 60))
  local s=$((total % 60))
  if [ "$h" -gt 0 ]; then printf "%dh %dm %ds" "$h" "$m" "$s"
  elif [ "$m" -gt 0 ]; then printf "%dm %ds" "$m" "$s"
  else printf "%ds" "$s"
  fi
}

# ==================== 排除规则 ====================
EXCLUDES=(
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
  '*/browser/*'
  '*.log'
  '*.tmp'
  '*.pid'
  '*.pyc'
  '*.data'
  '*.dat'
  '*.zip'
  '*.gz'
  '*.mp3'
  '*.mp4'
  '*.jpg'
  '*.png'
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
  exit 1
fi

T0_START=$(date +%s)
TOTAL_BYTES=0
for src_dir in "${EXIST_ABS[@]}"; do
  FIND_ARGS=()
  for pattern in "${EXCLUDES[@]}"; do
    if [[ "$pattern" == \*/* ]]; then
      dir_name=$(echo "$pattern" | sed 's|^\*/||; s|/\*$||')
      FIND_ARGS+=(-name "$dir_name" -prune -o)
    else
      FIND_ARGS+=(-name "$pattern" -prune -o)
    fi
  done
  CURRENT_SIZE=$(find "$src_dir" "${FIND_ARGS[@]}" -type f -print0 2>/dev/null | \
                 du -c --block-size=1 --files0-from=- 2>/dev/null | \
                 tail -n 1 | awk '{print $1}')
  if [ -n "$CURRENT_SIZE" ] && [ "$CURRENT_SIZE" -gt 0 ]; then
    TOTAL_BYTES=$((TOTAL_BYTES + CURRENT_SIZE))
  fi
done

T0_END=$(date +%s)
T0_COST=$((T0_END - T0_START))

TOTAL_GB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024/1024}')
TOTAL_MB=$(awk -v b="$TOTAL_BYTES" 'BEGIN {printf "%.2f", b/1024/1024}')

echo "Total:${TOTAL_GB} GB, (${TOTAL_MB} MB), $(fmt_duration $T0_COST)"
