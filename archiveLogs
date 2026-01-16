#! /bin/bash

TODAY=$(date +%Y-%m-%d)
ARCHIVE_DIR=/tmp/archives
mkdir -p $ARCHIVE_DIR

LOG_DIRS=(
  "/home/auser/Crawler/3/1/Deploy/logs"
  "/home/auser/Crawler/4/1/Deploy/logs"
  "/home/auser/Crawler/6/1/Deploy/logs"
  "/home/auser/Crawler/8/1/Deploy/logs"
  "/home/auser/Crawler/9/1/Deploy/logs"
  "/home/auser/Crawler/9/6/Deploy/logs"
  "/home/auser/Crawler/11/6/Deploy/logs"
  "/home/auser/Crawler/25/1/Deploy/logs"
  "/home/auser/Crawler/37/1/Deploy/logs"
  "/home/auser/Crawler/39/6/Deploy/logs"
  "/home/auser/Crawler/56/1/Deploy/logs"
  "/home/auser/Crawler/83/1/Deploy/logs"
  "/home/auser/Crawler/84/1/Deploy/logs"
  "/home/auser/Crawler/85/1/Deploy/logs"
  "/home/auser/TRClient/Agent/TC/logs/TCAgent"
  "/home/auser/TRClient/Agent/TC2/logs/TCAgent"
  "/home/auser/Crawler/3/8/Deploy/logs"
  "/home/auser/Crawler/3/7/Deploy/logs"
  "/home/auser/Crawler/3/24/Deploy/logs"
  "/home/auser/Crawler/7/7/Deploy/logs"
  "/home/auser/Crawler/15/8/Deploy/venv/lib/python3.7/site-packages/front_15_8/logs"
  "/home/auser/Crawler/34/14/Deploy/logs"
  "/home/auser/Crawler/27/8/Deploy/logs"
  "/home/auser/Crawler/6/2/Deploy/logs"
)


archive_logs() {
        local log_dir="$1"
        #echo "archiving $log_dir"
        find "$log_dir" -maxdepth 1 -type f -regextype posix-extended \
            -regex ".*/[0-9]+_[0-9]+_[0-9]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.log" \
            | sort -h | while IFS= read -r file; do

                filename=$(basename "$file")
                if [[ $filename =~ -([0-9]{4}-[0-9]{2}-[0-9]{2})\.log$ ]]; then
                        log_date="${BASH_REMATCH[1]}"
                else
                        continue
                fi
                if [[ "$log_date" == "$TODAY" ]]; then
                        continue
                fi

                archive_path="$ARCHIVE_DIR/${filename}.tar.gz"
                if [[ -f "$archive_path" ]]; then
                        echo "${filename} already exits, skipped."
                        continue
                fi

                tar -czf "$archive_path" -C "$(dirname "$file")" "$filename"
                rm -rf $archive_path
                echo "$archive_path archived."
        done
}

for dir in "${LOG_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            #echo "No such file or directory: $dir"
                continue
        fi
        archive_logs "$dir"
done
