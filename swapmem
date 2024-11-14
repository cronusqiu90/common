#! /bin/bash

size=$1

function add_swap() {
	echo "Create ${size} swap space"
	dd if=/dev/zero of=/swapfile bs=1M count=$size
	chmod 600 /swapfile
	ls -lh /swapfile
	mkswap /swapfile
	swapon /swapfile
	free -m
}

free_swap_size=`free -m | grep Swap|awk '{print$4}'`
if [ $free_swap_size -eq 0 ];then
	add_swap
fi
