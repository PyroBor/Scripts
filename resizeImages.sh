#!/bin/sh
in_dir="/home/bor/tmp/workdir/radar"
out_dir="/home/bor/tmp/workdir/radar/jpgs"
resolution="640x480"

cd $in_dir
for jpgfile in *; do
#basejpgfile=$(basename "$jpgfile")
convert -resize $resolution "$jpgfile" "$out_dir/$jpgfile"

done