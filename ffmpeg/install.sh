#! /bin/bash

cd /tmp
rm -rf ffmpegA
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xf ffmpeg-release-amd64-static.tar.xz -C /tmp/ffmpegA
mv /tmp/ffmpegA/ffmpeg-*-static/ff* /usr/local/bin
rm -rf /tmp/ffmpeg-release-amd64-static.tar.xz
rm -rf /tmp/ffmpegA
