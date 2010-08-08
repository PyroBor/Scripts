#!/bin/sh
music=/home/bor/music
templist=/home/bor/list.list
find $music -iname *.jpg >> $templist
find $music -iname *.png >> $templist

while read slika; do

path=${slika%/*}
cd "$path"

samoslika=${slika##*/}
[ ! -f "${samoslika%.*}.bmp" ] &&
echo "$path" &&
echo "$samoslika > ${samoslika%.*}.bmp" &&
convert "$samoslika" "${samoslika%.*}.bmp"

done < $templist
rm $templist