#!/bin/sh
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## sed script that adds headers to functions for bashdoc
##
#---

#---
## Shows usage
#---
function show_usage() {
usage="Usage:
$(basename $0) path/to/dir\t\t to edit all files in that dir
$(basename $0) path/to/file\t\t to edit only that file
$(basename $0) \t\t\t to edit all files in current dir [$(pwd)]
$(basename $0) --help|-h\t\t\t show this help
"
echo -e "$usage"
}


#---
## sed script...
## not the best. run it twice for best effect.
#---
function sed_script() {
  wanted_file=$1
  
  dash_line="#---"
  sed -i "
  :z
  /^[:space:]*$/  {
     # append next line
     n

     /^$/ { bz }
     #if is blank forget about it :)
     /main *()/ { bz }
     /usage *()/ { bz }
     /help *()/ { bz }
     /strip_parameters *()/ { bz }
     /process_parameters *()/ { bz }
     # also the functions that can be more files (main, help, process_parameters,
     # strip_parameters, usage). There are problems if there is more then one
     # function with same name.

     # lets search for functions
      /\w*()/ {

         #we have function in front
        /^function/ {
          s/\(function\) \(\w*\) *()/$dash_line\n##\n$dash_line\n\1 \2()/
          }
          #we don't... we add it.
        /^function/! {
          s/^\([a-z_^=]*\) *()/$dash_line\n##\n$dash_line\nfunction \1()/
        }

     }
  }

  # we should also have function name_function()
  # so lets change that even if we have header
  /\w*()/ {
       #we don't... we add it. (doesn't matter if header is ok.)
       /^function \w*()/! {
            s/^\([a-z_^=]*\) *()/function \1()/
  #           p
        }
  }
  " $wanted_file
}

#---
## lets run it twice
#---
function double_sed() {
  sed_script $1
  sed_script $1
}

# if someone wants to see help lets print it
while true; do
  case "$1" in
   "-h"|"--help")     show_usage;      exit 2 ;;
   *)                break ;;
  esac
done



if [[ -z $1 ]]; then
  # if there is no param
  for i in $(find ./*  ! -iname ".git" -type f); do double_sed $i ; done
elif [[ -d $1 ]]; then
  # param is directory
  for i in $(find $1/*  ! -iname ".git" -type f); do double_sed $i ; done
elif [[ -f $1 ]]; then
  # param is file
  double_sed $1
else
  echo "something is wrong with path"
fi


