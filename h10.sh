#!/bin/bash
rsync -r -n -t --progress --delete --ignore-existing --size-only /home/bor/music/ /mnt/iriver/Music/
