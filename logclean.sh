#! /bin/bash

function cleanDir(){
    local dirPath=$1
    if [ -d "$dirPath" ];then
        cd $dirPath
        rm -rf *2021*
        rm -rf *2022*
        rm -rf *2023*
        rm -rf *2024-01*
        rm -rf *2024-02*
        rm -rf *2024-03*
        rm -rf *2024-04*
        rm -rf *2024-05*
        truncatet -s 0 ERROR*

        find . -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
            fsize=$(stat -c "%s" "$file")
            fsizeMB=$(echo "scale=2; $fsize / 1024 / 1024" | bc)
            if (( $(awk -v size="$file_size_mb" 'BEGIN {print (size > 20 ? 1 : 0)}') )); then
                #truncate -s 0 file
                echo "truncate -s 0 $file"
            fi
        done
    fi
}


cleanDir $1
