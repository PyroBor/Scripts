#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## Renames files based on filename or imdb
##
## TODO
## - elinks doesn't work anymore with imdb...
#---
flags="0tv|n0tv|fqm|xor|2hd|0tv|C4TV|720p|1080p|x264|X264|2009"
wanted_dir="$(pwd)"
seria="$(basename "$(pwd)")"
imdb="no"
imdb_url="blank"
#selection_of_files="*.avi *.ogm *.srt"
selection_of_files="*.avi"
elinks="/usr/bin/links"
subtitle="no"
subtitleOW="no"
# newname_format='$seria ${season}x$zeroepisode $episode_title.$file_extension'
format="1"
trap 'echo "exiting" && cleantmpdir && exit 1' INT

function coolsleep {
  local time_to_sleep=$1
  echo -n "Now sleeping to not get banned:"
  until [[ $time_to_sleep == "0" ]]; do
    echo -n "$time_to_sleep "
    sleep 1
    let time_to_sleep--
  done
  echo
}

USAGE="USAGE:
--wanted_dir <path>\t Rename files in folder [$wanted_dir]
-h, --help \t\t Shows this help.
-s, --seria \t\t specify seria name or dirname will be used [$seria]
-l, --links \t\t specify text web browser (links, elinks; others are not tested) [$elinks]
--imdb \t\t\t Enable use of www.imdb.com will use the first hit on search for seria (needs elinks) [$imdb]
-u, --imdb_url \t\t If you seria is not the first hit specify imdb link here [$imdb_url]
--selection \t\t what files to use [$selection_of_files]
--subtitle \t\t toggle download of subtitles [$subtitle]
--subtitleOW \t\t toggle download of subtitles and overwrite of them [$subtitleOW]
-f, --format \t\t see --help-format to see available formats [$format]
-F,--one-file \t\t to use onle for one file.
"
FORMATHELP="choose with --format
with imdb:
1) Seria 2x02 Title.avi
2) Seria 2x2 Title.avi
3) Seria 202 Title.avi
4) Seria 02x02 Title.avi
5) 2x02 Title.avi
6) 02x02 Title.avi
without imdb:
11) Seria 2x02.avi
12) Seria 2x2.avi
13) Seria 202.avi
"




## @param dirfile (not yet)
function maketmpdir (){
  mkdir -p "/tmp/$seria"
  TMPDIR="/tmp/$seria"
}

## del tmp dir at the end
function cleantmpdir (){
  rm -rf "$TMPDIR"
}

##
## @Parm seria
## @parm season
## @parm episode
## @parm lang
##
function get_subtitles (){
  local lang=1 #angleščina=2 slovenščina=1 vsi jeziki=0
  maketmpdir
  mkdir -p "$TMPDIR/$season-$episode"
  cd "$TMPDIR/$season-$episode"
      # http://www.sub-titles.net/ppodnapisi/search?tbsl=3&asdp=1&sK=boston+legal&sJ=2&sTS=1&sTE=1#
      # http://www.sub-titles.net/ppodnapisi/search?tbsl=3&asdp=1&sK=boston+legal&sJ=2&sO=asc&sS=time
      # if we sort by time we get better results... i think... all is a bit gambling :)
  if [ -f "$wanted_dir/$newname_naked.srt" ] && [ $subtitleOW == "no" ]; then
    echo "there are allready one subtitles go with --subtitleOW to overwrite"
  else
    download_link=$($elinks -source "http://www.sub-titles.net/sl/ppodnapisi/search?tbsl=3&asdp=1&sK=$seria&sJ=$lang&sTS=$season&sTE=$episode&sO=asc&sS=time" |grep -m1 -E -o  "/sl/ppodnapisi/podnapis/i/[0-9a-Z/-]*")
    if [[ $download_link ]]; then
      wget -q  "http://www.sub-titles.net$download_link"
      unzip -qq *.zip
      srt_file=$(find ./ -iname "*.srt" |head -n1)
      #rm *.zip
      chmod 666 "$srt_file"
      mv "$srt_file" "$wanted_dir/$newname_naked.srt"
      echo "Got subtitles: $srt_file >> $wanted_dir/$newname_naked.srt"
      coolsleep 20
    else
      echo "no subititles found"
    fi
  fi
  cleantmpdir
  cd "$WORKING_DIR"
}

## download it to tmp dir and have it there util the end of script
## we will clean tmp dirs at the end.
function get_imdb_episode_title () {
  cd "$TMPDIR"
  [[ "$imdb_url" == "blank" ]] && imdb_url=$($elinks -dump "http://www.imdb.com/find?s=tt&q=$seria" |grep -m1 -E -o "http://www.imdb.com/title/tt[0-9]*/")
  #stupid imdb. this will stop working with clips on the site
  [[ ! -f episodes ]] && $elinks -dump $imdb_url'episodes' > episodes
  episode_title=$(grep "Season $season, Episode $episode:" episodes |sed s/.*:\ //)
  cd "$WORKING_DIR"
}

## Parse the command line parameters and arguments via getopt
TEMP_OPTS=$(getopt -o 's:u:f:F:l_h' -l 'wanted_dir:,seria:,imdb,imdb_url:,subtitle,\
subtitleOW,selection:,format:,links:,format-custom:,one-file:,help-format,help' \
-n "$(basename $0)" -- "$@")
if [[ $? != 0 ]]; then  echo -e "$USAGE"; exit 3; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP_OPTS"
unset TEMP_OPTS

while true; do
  case "$1" in
    "--wanted_dir")        wanted_dir="$2";                 shift 2 ;;
    "-l"|"--links")        elinks="$2"                      shift 2 ;;
    "-s"|"--seria")        seria="$2";                      shift 2 ;;
    "--imdb")              imdb=yes;                        shift   ;;
    "-u"|"--imdb_url")     imdb=yes; imdb_url="$2";         shift 2 ;;
    "--subtitle")          subtitle=yes;                    shift   ;;
    "--subtitleOW")        subtitle=yes && subtitleOW=yes;  shift   ;;
    "--selection")         selection_of_files="$2";         shift 2 ;;
    "-f"|"--format")       format="$2";                     shift 2 ;;
    "--format-custom")     newname_format="$2";             shift 2 ;;
    "-F"|"--one-file")     selected_files="$2";             shift 2 ;;
    "--help-format")       echo -e "$FORMATHELP";           exit 0  ;;
    "-h"|"--help")         echo -e "$USAGE";                exit 0  ;;
    --)                    shift ;                          break   ;;
    *)                     echo -e "$USAGE";                exit 3  ;;
  esac
done


if [[ $format ]]; then
  case "$format" in
  "1") newname_format='$seria ${season}x$zeroepisode $episode_title' ;;
  "2") newname_format='$seria ${season}x$episode $episode_title' ;;
  "3") newname_format='$seria $season$zeroepisode $episode_title' ;;
  "4") newname_format='$seria ${zeroseason}x$zeroepisode $episode_title'   ;;
  "5") newname_format='${season}x$zeroepisode $episode_title'  ;;
  "6") newname_format='${zeroseason}x$zeroepisode $episode_title'  ;;
  "11") newname_format='$seria ${season}x$zeroepisode' ;;
  "12") newname_format='$seria ${season}x$episode' ;;
  "13") newname_format='$seria $season$zeroepisode' ;;
  esac
fi


WORKING_DIR="$wanted_dir"
maketmpdir


if [[ $selected_files ]]; then
  unset selection_of_files
fi


cd "$wanted_dir"
for oldname in "$selected_files" $selection_of_files; do
[[ -f $oldname ]] || continue
  file_extension=${oldname##*.}
#   file_seria=${oldname%%[0-9]*}
  clean_oldname=$(sed -r -e "s/($flags)//gi" <<< $oldname)
    # ^ removing flags that contain numbers
  some_numbers=$(grep -o -E "([0-9]*)" <<< $clean_oldname)
  # working for such formats:
  # serija s1e12.avi
  # serija 2x11.avi
  # serija 801 blaaa.avi
  # serija 2012.avi
  # basicly those which numbers mean season and episode
  # and there is no other numbers in filename
  # DON'T USE IT FOR:
  # numb3rs.se04.ep12.blaaa.avi
  # seria.se04.ep12.blaaa2.avi
  numbers=$(sed -e "s/ //" <<< $some_numbers)
  if [[ ${#numbers} == "3" ]]; then
    season=${numbers:0:1}
    zeroseason="0$season"
    zeroepisode=${numbers:1:2}
    episode=$(sed -r -e "s/(0)([1-9])/\2/" <<< $zeroepisode)
  elif [[ ${#numbers} == "2" ]]; then
    season=${numbers:0:1}
    zeroseason="0$season"
    episode=${numbers:1:2}
    zeroepisode="0$episode"
  elif [[ ${#numbers} == "0" ]]; then
    echo "$oldname ERROR: no nubmers found"
    nonumbers=1
  else
      zeroseason=${numbers:0:2}
      season=$(sed -r -e "s/(0)([1-9])/\2/" <<< $zeroseason)
      zeroepisode=${numbers:2:2}
      episode=$(sed -r -e "s/(0)([1-9])/\2/" <<< $zeroepisode)
  fi

  # for now without params
  [[ "$imdb" == "yes" ]] && get_imdb_episode_title
  
  newname_naked="$(eval echo $newname_format)"

  
  [[ "$subtitle" == yes ]] && get_subtitles
  if  [[ $nonumbers == 1 ]]; then
    newname="$oldname"
  else
    newname="${newname_naked}.$file_extension"
  fi

  if [[ "$oldname" != "$newname" ]]; then
    mv -n "$oldname" "$newname"
    echo "$oldname >>> $newname"
  fi
  unset episode season pre_episode pre_season zeroepisode zeroseason newname nonumbers
done

cleantmpdir
