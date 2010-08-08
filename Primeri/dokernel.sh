#!/bin/bash
# by lynx
# requires gentoolkit (unless you use the EXPERIMENTAL code)
# http://lynxlynx.info/wiki/doku.php?id=dokernel
# change one of these two vars if you want automatic *.conf fixes; read their respective comments and script usage!
LILOBLOCK='
image = /boot/kernel-MRVERTOBE
initrd = /boot/fbsplash-mojafb-1024x768
root = /dev/hda7
label = Gentoo
append="video=vesafb:ywrap,mtrr,1024x768-16@85 splash=verbose,fadein,theme:mojafb CONSOLE=/dev/tty1"
read-only' # change this to your prefered lilo kernel block. Keep the image line!
GRUBBLOCK='
title=Gentoo Linux MRVERTOBE
root (hd0,1)
kernel /kernel-MRVERTOBE quiet root=/dev/sda4 video=vesafb:ywrap,mtrr,1024x768-16@60 splash=silent,theme:selfportrait CONSOLE=/dev/tty1
initrd /fbsplash-selfportrait' # change this to your prefered grub kernel block. Keep the title line and "/kernel-MRVERTOBE" in the kernel one!
ADDITIONALPKGS= #add anything you want to get emerged after the kernel compilation excluding nvidia/ati drivers
#
#-------------------nothing crucial left to read/modify ahead---------------------

# colors
E="\e[0m" # end
Y="\e[33;1m"
R="\e[31;1m"
G="\e[32;1m"

USAGE="${Y}USAGE: $0 [OPTIONS]:$E
  ${Y}-v, --verbose$E \t be more verbose [off]
  ${Y}-y, --i-know-what-i-am-doing-cause-i-have-edited-the-header-as-needed$E \t use this to run this script $G[off]$E
  ${Y} --want-lilo [path]$E \t toggle automagical lilo.conf updates; if a valid path is given, take that file as the LILOBLOCK $G[off]$E
  ${Y}--want-grub [path]$E \t toggle automagical grub.conf updates; if a valid path is given, take that file as the GRUBBLOCK $G[off]$E
  ${Y}--lilo-conf <path>$E \t full path to your lilo.conf $G[/etc/lilo.conf]$E
  ${Y}--grub-conf <path>$E \t full path to your grub.conf / menu.lst $G[/boot/boot/grub.conf]$E
  ${Y}--boot-mp <path>$E \t your /boot partition mountpoint OR where you store your kernel $G[/boot]$E
  ${Y}--fly$E \t use fast experimental mode (as in dangerous!) $G[off]$E
  ${Y}-a, --also \"<pkg1 ... pkgn>\"$E \t emerge additional packages after kernel 
                               \t installation excluding nvidia or ati drivers $G[empty]$E
  ${Y}-h, --help$E \t show this help message"

# setting all vars to defaults
EXPERIMENTAL=no #let it be if set, otherwise set to "no"
OUTPUT=/dev/null # set this to /dev/null for quiet build mode. /dev/stdout means it will redirect to standard output
BOOTMP=/boot #your /boot partition mountpoint OR your equivalent of /boot on your root partition. WITHOUT THE TRAILING SLASH!
IWANTLILO=no # if you want the magical lilo update; be sure your lilo.conf has \n delimited image blocks
IWANTGRUB=no # if you want the magical grub update; be sure your grub.conf has \n delimeted image blocks
GRUBCONF=/boot/boot/grub.conf # set this to where your grub.conf / menu.lst is
LILOCONF=/etc/lilo.conf # set this to where your lilo.conf is
IKNOWWHATIMDOING=no

#check and react on commandline parameters. Code from bashfaq, saved me getopt/s work
if [[ -z "$1" ]]; then echo -e "$USAGE"; exit 0; fi # 1) no params
while [[ "$1" == -* ]] # 2) params
do
    case "$1" in
    "-y"|"--i-know-what-i-am-doing-cause-i-have-edited-the-header-as-needed")
        IKNOWWHATIMDOING=yes
    ;;
    "-l"|"--want-lilo")
        IWANTLILO=yes
        [[ -f $2 ]] && LILOBLOCK="
$(<$2)" &&
        shift
    ;;
    "-g"|"--want-grub")
        IWANTGRUB=yes
        [[ -f $2 ]] && GRUBBLOCK="
$(<$2)" &&
        shift
    ;;
    "--lilo-conf")
        LILOCONF=$2; GRUBCONF=/non/existing/path
        shift # an extra shift is needed since we use two parameters
    ;;
    "--grub-conf")
        GRUBCONF=$2; LILOCONF=/non/existing/path
        shift # an extra shift is needed since we use two parameters
    ;;
    "--boot-mp")
        BOOTMP=$2
        [ "${BOOTMP:${#BOOTMP}-1:1}" == "/" ] && BOOTMP=${BOOTMP:0:${#BOOTMP}-1} # remove trailing / if any
        shift
    ;;
    "-v"|"--verbose")
        OUTPUT=/dev/stdout
    ;;
    "--fly")
        EXPERIMENTAL=yes
    ;;
    "--also"|"-a")
        ADDITIONALPKGS="$1"
        shift
    ;;
    "-h"|"--help"|*)
        echo -e "$USAGE"
        exit 0
    ;;
    esac
    shift
done
if [ ! -z "$1" ]; then echo -e "$USAGE"; exit 0; fi # 3) bad params or anything else

function error
{
  echo -e "$R$1$E"
  exit ${2:-111}
}

#sanity checks
if test $IKNOWWHATIMDOING == "no"; then exit 42; fi
if [ "$IWANTGRUB" = "yes" ] && [ "$IWANTLILO" = "yes" ]; then error "Choose one or neither, you can't have \$IWANTGRUB and \$IWANTLILO both set to yes." 1; fi
if [ ! -e "$GRUBCONF" ] && [ ! -e "$LILOCONF" ]; then error "Bad lilo.conf or grub.conf path. Exiting..." 14; fi
#if [[ ! -e $GRUBCONF && "$IWANTGRUB" = "yes" ]]; then error "Bad grub.conf path, fixing grub would fail. Exiting..." 15; fi
#if [[ ! -e $LILOCONF && "$IWANTLILO" = "yes" ]]; then error "Bad lilo.conf path, fixing lilo would fail. Exiting..." 15; fi
[ ! -e "$BOOTMP" ] && error "You set \$BOOTMP to something wierd, fix it; exiting..." 1

echo -e "$G--- -- - DoKernel script started - -- ---$E" && echo

# unalias ls ##no need, since aliases don't expand in scripts

function getVersionNum
{
  #makes the version in 0206ABCD format (stripped) for proper comparison and sort
  local TEMPVER=`echo $1 | sed 's/[a-z]//g'| tr '-' '\n' | tr '.' '\012' | sed 's/^[[:digit:]]$/0&/' | tr -d '\n'`
  echo $TEMPVER
}

function mostRecentVersion
{
  if [ -z MRVER ];
  then MRVERn=$2 && MRVER=$1
  else
    if [[ "$2" > "$MRVERn" ]];
    then MRVERn=$2 && MRVER=$1
    fi
  fi
return 0
}

function askExit
{
  echo -ne "${Y}Continue? [n/*] $E"
  read -n1 ANSWER
  if [ "${ANSWER:-y}" == "n" ]; then echo && unprep_boot && exit 0; fi
  echo -e "\n"
return 0
}

function getInput
{
  read -n1 # read writes the input to REPLY if no vars are given
  echo "${REPLY:-%}" # so input from $IFS works too (tab, space, enter)
}

function prepare_boot
{
  if grep -wq "$BOOTMP" /etc/fstab
  then # dealing with a mountpoint
    if grep -q boot /etc/mtab; #already mounted?
    then SEPBOOT=false # so this check doesn't have to be repeated when umounting
    else mount $BOOTMP && SEPBOOT=true
    fi
  else # dealing with /boot on root
    SEPBOOT=false # true and false are actually shell builtins. This enables the easy check in unprep_boot
  fi
return 0
}

function unprep_boot
{
  if ${SEPBOOT-false} # not really needed, unintialized variables test false
  then
    umount $BOOTMP
  fi
}

echo "Locally available kernel sources:"
I=1
if [ "$EXPERIMENTAL" == "yes" ]
then
  #EXPERIMENTAL and NOT FOOLPROOF but WAY FASTER. You need to have a maintained /usr/src to try this out (or add a check for old kernel sources leftovers).
  for KERNEL in $(ls -1vl /usr/src | sed -n '/^d/ s/.*linux-//p' | sed 's/-gentoo-/-/')
  do
    echo "$KERNEL"
    VERARR[$I]="$KERNEL"
    ((I++))
    mostRecentVersion "$KERNEL" `getVersionNum "$KERNEL"`
  done

  #newest in portage - will see masked ones too @@@doesn't work for non-revision releases
  MRPORTVER=$(ls -R1vrI "*[mfC]*" /usr/portage/sys-kernel/gentoo-sources | sed -n 's/gentoo-sources-\(.*\).ebuild/\1/p' | head -n1)
  #/EXPERIMENTAL
else
  #get installed kernel source versions;
  for KERNEL in `equery list gentoo-sources | grep '2' | cut -d'-' -f4-`;
  do
    echo "$KERNEL"
    VERARR[$I]="$KERNEL"
    ((I++))
    mostRecentVersion "$KERNEL" `getVersionNum "$KERNEL"`
  done

  #newest in portage. Probably, equery is wierd, etcat++.
  MRPORTVER="$(equery l gentoo-sources | tail -n1 | sed 's,^[^2]*,,')"
fi

#comparison
echo
echo "Most recent portage version: $MRPORTVER"
mostRecentVersion "$MRPORTVER" `getVersionNum "$MRPORTVER"`
echo "Most recent version: $MRVER"
echo -n "Last installed: "
uname -r | sed 's/gentoo-//'
echo
if [ "`uname -r | sed 's/gentoo-//'`" == "$MRVER" ];
then echo -e "${Y}Newest stable kernel already installed.$E"
else echo -e "${G}Newer stable kernel available.$E"
fi

askExit

echo -e "$G--- -- - Preparing for installation - -- ---\012$E" ########################
#portage group || root required
emerge -pv gentoo-sources | grep "\[" || su -c "emerge -pv gentoo-sources | grep '\['"
#funky grep exit codes allow this: 0-found 1-not 2-error
#+so if emerge fails, grep will too -> su...
echo

#main menu :)
echo -e "${Y}What to do next?$E"
echo "[1] (Re)Install the newest available kernel"
echo "[5] Uninstall kernel source(s)"
echo "[9] Uninstall kernel(s)"
echo "[*] Exit before foobaring something."
read -n1 answer
case "${answer:-n}" in
"1" )
  echo; echo
  [ "$UID" == "0" ] || error "Restart the script; you need to be root to install a kernel!" 5
  emerge -nq gentoo-sources >$OUTPUT || error "emerge failed! Exiting..." 6
  LASTVER=`ls -l /usr/src/linux | cut -d'>' -f2` #first save the link for later use
  prepare_boot
  echo -e "\nDEBUG# $LASTVER # "$LASTVER
  echo -e "${Y}To continue with make, press 'm'. Normally you wouldn't, this is for the case you quit after making *config. It's also still safe to ^C. [m,*] ?$E"
  if [ `getInput` != "m" ];
  then
    echo -e "\n\nSymlinking sources..."
    rm /usr/src/linux
    ln -s /usr/src/linux-${MRVER/-/-gentoo-} /usr/src/linux
    cd /usr/src/linux
    #maybe permanently change MRVER if no later use found

    # cleaning, for reinstalls and failed builds
    echo "Making clean..."
    make clean &> /dev/null

    echo
    # copy old config or continue
    echo -e "${Y}Use (p)revious config or start a(n)ew? [p,*]?$E"
    if [ `getInput` == "p" ];
    then
      cp $LASTVER/.config /usr/src/linux/.config || echo "No previous config found or a reinstall (nothing bad then)."
    fi

    echo
    # make oldconfig/xconfig
    echo -e "${Y}Make (o)ldconfig, (m)enuconfig or (x)config? [o,m,*]?$E"
    a=`getInput`
    if [ "$a" == "o" ];
    then
      make oldconfig || error "No previous config found or make failed. Quitting now - you should either get the .config or choose a different option." 20
      #no check if user was dumb enough to not answer 'p' before
    elif [ "$a" == "m" ];
    then
      make menuconfig || error "Make failed." 21
    else
      make xconfig || error "Make failed." 22
    fi
    echo
    askExit
  fi

  cd /usr/src/linux
  echo -e "${G}--- -- - Compile time - -- ---$E"
  echo -e "Making all and modules_install:\n"
  make >$OUTPUT && make modules_install >$OUTPUT && echo -e '\nWeeee, it worked!' || error "make failed! Exiting..." 7

  echo
  echo "Copying stuff to ${BOOTMP}..."
  cp arch/i386/boot/bzImage $BOOTMP/kernel-${MRVER/-/-gentoo-} && echo "bzImage: done"
  cp .config $BOOTMP/config-${MRVER/-/-gentoo-} && echo ".config: done"
  cp System.map $BOOTMP/System.map-${MRVER/-/-gentoo-} && echo "System.map: done"

  echo
  if test "$IWANTLILO" == "yes"; # cool fix
  then
    echo "Editing lilo.conf..."
    # change the last latest kernel name to it's version, unless it's a reinstall
    if [ `sed -e 's/linux-//' -e 's,.*/,,'<<<$LASTVER` != ${MRVER/-/-gentoo-} ]
    then
      sed -i 's/ Gentoo$/'`echo $LASTVER | xargs basename | sed -e 's/gentoo-//' -e 's/linux-//'`'/' $LILOCONF
    fi
    # for reinstalls
    if [ `grep -c ${MRVER/-/-gentoo-} $LILOCONF` -ge 1 ];
    then lilo -C $LILOCONF #just to be sure
    else
      #this is a cool trick I learned from the ebuild guides - here strings save some processes
      sed 's,MRVERTOBE,'${MRVER/-/-gentoo-}','<<<"$LILOBLOCK" >> $LILOCONF
      lilo -C $LILOCONF
    fi
  elif test "$IWANTGRUB" == "yes"; # cool fix #2
  then
    echo "Editing grub.conf..."
    # for reinstalls
    if [ `grep -c ${MRVER/-/-gentoo-} $GRUBCONF` -ge "1" ];
    then :
    else
      sed -e '/title/ s,MRVERTOBE,'${MRVER}',' -e 's,MRVERTOBE,'${MRVER/-/-gentoo-}','<<<"$GRUBBLOCK" >> $GRUBCONF
    fi
  else
    if [ -e $LILOCONF ];
    then
      ${EDITOR:-nano} $LILOCONF; lilo -C $LILOCONF
    else
      ${EDITOR:-nano} $GRUBCONF
    fi
  fi

  echo
  echo -e "${Y}Do you want to rebuild your nvidia drivers (provided you use them)? [y,*]$E"
  if [ `getInput` == "y" ];
  then
    emerge nvidia-drivers >$OUTPUT && ( eselect opengl set nvidia || opengl-update nvidia ) || echo -e "${R}emerge failed! Fix it yourself...$E"
  else
    echo
    echo -e "${Y}Do you want to rebuild your ati drivers (provided you use them)? [y,*]$E"
    if [ `getInput` == "y" ];
    then
      emerge ati-drivers >$OUTPUT && ( eselect opengl set ati || opengl-update ati ) || echo -e "${R}emerge failed! Fix it yourself...$E"
    fi
  fi

  [[ ! -z $ADDITIONALPKGS ]] && 
    echo -e "${G}Emerging additional packages...$E" &&
    emerge $ADDITIONALPKGS >$OUTPUT

  echo && echo -e "${G}Kernel succesfully installed, exiting... Don't forget to reboot.$E" && unprep_boot && exit 0
#exit 2 #what? oddddd heh seems it just exits from this "case", switching back to start
;;
########################################################################################
"5" )
echo -e "$G--- -- - Uninstalling sources - -- ---$E" ###################################
  echo -e "\n"
  echo "Versions of installed sources with their indexes:"
  echo ${VERARR[@]}
  echo -n "  "
  seq -s "     " 1 ${#VERARR[@]}
  [ "$UID" == "0" ] || error "Restart the script; you need to be root to uninstall kernel sources!" 5
  echo -e "${Y}Now pick the index of the source(s) you want to uninstall (separated by space): $E"
  read indexx
  for index in $indexx #intentionally not "commented". I think (some weeks later). ><
  do
    emerge -Cpv =gentoo-sources-${VERARR[$index]}
    askExit
    emerge -C =gentoo-sources-${VERARR[$index]} >$OUTPUT
    rm -rf /usr/src/linux-${VERARR[$index]/-/-gentoo-}
  done # a for loop will have the exit code of the last executed command
  if [ $? = 0 ]; then echo -e "${G}Removal succeded, exiting...$E" && exit 0; else error "Something went awry!" 31; fi
;;
"9" )
#####################################################################################
echo -e "${G}--- -- - Uninstalling kernels - -- ---$E" #################################
  echo && echo
  [ "$UID" == "0" ] || error "Restart the script; you need to be root to uninstall kernels!" 5
  prepare_boot
  echo "Installed kernels:"
  I=1
  for KERNEL in `ls -v1 $BOOTMP | grep kernel | grep -n ""`;
  do
    sed -e 's/kernel-//' -e 's/:/&\t/'<<<"$KERNEL"
    KERNEL=${KERNEL#*:}
    VERARR[$I]="$KERNEL"
    ((I++))
  done

  echo
  askExit
  echo -e "${Y}Which kernel(s) to uninstall (separated by space)(fixes lilo/grub too, if IWANT* is set to \"yes\")?$E"
  read indexs
  set --
  set $indexs

  while [ "$#" != "0" ]
  do
    index=$1
    rm $BOOTMP/${VERARR[$index]} &&
    rm $BOOTMP/config${VERARR[$index]##kernel} &&
    rm $BOOTMP/System.map${VERARR[$index]##kernel} &&
    rm -rf /lib/modules/2${VERARR[$index]##kernel-2} # the -2 is a precaution - this way nothing would be deleted in the bad case of $VERARR not being set or empty
    if [ "$IWANTLILO" == "yes" ]; then
      sed -i '/'${VERARR[$index]}'/,/^$/d' $LILOCONF;
      lilo -C $LILOCONF
    fi
    if [ "$IWANTGRUB" == "yes" ]; then
      sed -i '/title=[^2]*'${VERARR[$index]/-/-gentoo-}'/,/^$/d' $GRUBCONF
    fi
    # REQUIRES blank line image separators which this script provides aplenty
    shift
  done

  if [[ $? = 0 ]]; # not an assignement!
  then 
    echo -e "${G}Removal succeded, exiting...$E" &&
    unprep_boot &&
    exit 0
  else
    error "Gosh, something bad just happened!" 41
  fi
;;
* ) echo && exit 0 ;;
esac

echo "lalalalala" #this line will never echo. I always wanted to do this sometime :D

