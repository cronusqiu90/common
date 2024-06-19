#!/bin/bash

target=$1

rm -rf $target/*2021*.log
rm -rf $target/*2022*.log
rm -rf $target/*2023*.log
rm -rf $target/*2024-01*.log
rm -rf $target/*2024-02*.log
rm -rf $target/*2024-03*.log
rm -rf $target/*2024-04*.log
rm -rf $target/*2024-05*.log

find $target -type f -name "*.log" -print0 | while IFS= read -r -d $'\0' filePath; do
    fileName=$(basename "$filePath")
    if [[ $fileName =~ ^[1-9] ]];then
        echo "[-]    $filePath"
        continue
    fi

    echo "[*] $filePath"

    fsize=$(stat -c "%s" "$filePath")
    fsizeMB=$(echo "scale=2; $fsize / 1024 / 1024" | bc)
    if (( $(awk -v size="$fsizeMB" 'BEGIN {print (size > 20 ? 1 : 0)}') )); then
        echo "[+] $filePath   [$fsizeMB] "
        truncate -s 0 $filePath
    fi
done
