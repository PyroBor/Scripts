#!/bin/bash
seria="Boston Legal"
season=1
episode=2
wanted_dir="/home/bor/tmp"
lang=2 #angleščina=2 slovenščina=1 vsi jeziki=0
mkdir "/tmp/$seria"
cd "/tmp/$seria"
# http://www.sub-titles.net/ppodnapisi/search?tbsl=3&asdp=1&sK=boston+legal&sJ=2&sTS=1&sTE=1#
# http://www.sub-titles.net/ppodnapisi/search?tbsl=3&asdp=1&sK=boston+legal&sJ=2
download_link=$(elinks --dump "http://www.sub-titles.net/ppodnapisi/search?tbsl=3&asdp=1&sK=$seria&sJ=$lang&sTS=$season&sTE=$episode#" |grep -m1 -E -o  "http://www.sub-titles.net/ppodnapisi/download/i/.*")
wget $download_link
unzip *.zip

srt_file=$(find ./ -iname "*.srt")
#rm *.zip
mv "$srt_file" "$wanted_dir"

## cleanup
rm -rf "/tmp/$seria"
cd -
#rm "$srt_file"