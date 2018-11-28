##########################################################################################
#
# Terminal Utility Functions
# by veez21
#
##########################################################################################

# Versions
MODUTILVER=v2.3.1
MODUTILVCODE=231

# Check A/B slot
if [ -d /system_root ]; then
  isABDevice=true
  SYSTEM=/system_root/system
  SYSTEM2=/system
  CACHELOC=/data/cache
else
  isABDevice=false
  SYSTEM=/system
  SYSTEM2=/system
  CACHELOC=/cache
fi
[ -z "$isABDevice" ] && { echo "Something went wrong!"; exit 1; }

#=========================== Set Busybox up
# Variables:
#  BBok - If busybox detection was ok (true/false)
#  _bb - Busybox binary directory
#  _bbname - Busybox name

# set_busybox <busybox binary>
# alias busybox applets
set_busybox() {
  if [ -x "$1" ]; then
    for i in $(${1} --list); do
      if [ "$i" != 'echo' ]; then
        alias "$i"="${1} $i" >>$LOG 2>&1
      fi
    done
    _busybox=true
    _bb=$1
  fi
}
_busybox=false
if [ -d /sbin/.core/busybox ]; then
  PATH=/sbin/.core/busybox:$PATH
  _bb=/sbin/.core/busybox/busybox
  _busybox=true
elif [ ! -x $SYSTEM/xbin/busybox ]; then
  set_busybox /data/magisk/busybox
  set_busybox /data/adb/magisk/busybox
else
  alias busybox=""
fi
if [ $_busybox ]; then
  true
elif [ -x $SYSTEM/xbin/busybox ]; then
  _bb=$SYSTEM/xbin/busybox
elif [ -x $SYSTEM/bin/busybox ]; then
  _bb=$SYSTEM/bin/busybox
else
  echo "! Busybox not detected"
  echo "Please install one (@osm0sis' busybox recommended)"
  false
fi
[ $? -ne 0 ] && exit $?
alias echo='echo -e'
[ -n "$LOGNAME" ] && alias clear='echo'
_bbname="$($_bb | head -n1 | awk '{print $1,$2}')"
BBok=true
if [ "$_bbname" == "" ]; then
  _bbname="BusyBox not found!"
  BBok=false
fi

#=========================== Default Functions and Variables

# Device Info
# Variables: BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
api_level_arch_detect

# Version Number
VER=$(grep_prop version $MODDIR/module.prop)
# Version Code
REL=$(grep_prop versionCode $MODDIR/module.prop)
# Author
AUTHOR=$(grep_prop author $MODDIR/module.prop)
# Mod Name/Title
MODTITLE=$(grep_prop name $MODDIR/module.prop)

# Colors
G='\e[01;32m'		# GREEN TEXT
R='\e[01;31m'		# RED TEXT
Y='\e[01;33m'		# YELLOW TEXT
B='\e[01;34m'		# BLUE TEXT
V='\e[01;35m'		# VIOLET TEXT
Bl='\e[01;30m'		# BLACK TEXT
C='\e[01;36m'		# CYAN TEXT
W='\e[01;37m'		# WHITE TEXT
BGBL='\e[1;30;47m'	# Background W Text Bl
N='\e[0m'			# How to use (example): echo "${G}example${N}"
loadBar=' '			# Load UI
# Remove color codes if -nc or in ADB Shell
[ -n "$1" -a "$1" == "-nc" ] && shift && NC=true
[ "$NC" -o -n "$LOGNAME" ] && {
  G=''; R=''; Y=''; B=''; V=''; Bl=''; C=''; W=''; N=''; BGBL=''; loadBar='=';
}

# No. of characters in $MODTITLE, $VER, and $REL
character_no=$(echo "$MODTITLE $VER $REL" | wc -c)

# Divider
div="${Bl}$(printf '%*s' "${character_no}" '' | tr " " "=")${N}"

# title_div [-c] <title>
# based on $div with <title>
title_div() {
  [ "$1" == "-c" ] && local character_no=$2 && shift 2
  [ -z "$1" ] && { local message=; no=0; } || { local message="$@ "; local no=$(echo "$@" | wc -c); }
  [ $character_no -gt $no ] && local extdiv=$((character_no-no)) || { echo "Invalid!"; return; }
  echo "${W}$message${N}${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# set_file_prop <property> <value> <prop.file>
set_file_prop() {
  if [ -f "$3" ]; then
    if grep "$1=" "$3"; then
      sed -i "s/${1}=.*/${1}=${2}/g" "$3"
    else
      echo "$1=$2" >> "$3"
    fi
  else
    echo "$3 doesn't exist!"
  fi
}

# https://github.com/fearside/ProgressBar
# ProgressBar <progress> <total>
ProgressBar() {
# Determine Screen Size
  if [[ "$COLUMNS" -le "57" ]]; then
    local var1=2
	local var2=20
  else
    local var1=4
    local var2=40
  fi
# Process data
  local _progress=$(((${1}*100/${2}*100)/100))
  local _done=$(((${_progress}*${var1})/10))
  local _left=$((${var2}-$_done))
# Build progressbar string lengths
  local _done=$(printf "%${_done}s")
  local _left=$(printf "%${_left}s")

# Build progressbar strings and print the ProgressBar line
printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

#https://github.com/fearside/SimpleProgressSpinner
# Spinner <message>
Spinner() {

# Choose which character to show.
case ${_indicator} in
  "|") _indicator="/";;
  "/") _indicator="-";;
  "-") _indicator="\\";;
  "\\") _indicator="|";;
  # Initiate spinner character
  *) _indicator="\\";;
esac

# Print simple progress spinner
printf "\r${@} [${_indicator}]"
}

# cmd & spinner <message>
e_spinner() {
  PID=$!
  h=0; anim='-\|/';
  while [ -d /proc/$PID ]; do
    h=$(((h+1)%4))
    sleep 0.02
    printf "\r${@} [${anim:$h:1}]"
  done
}

# test_connection
# tests if there's internet connection
test_connection() {
  echo -n "Testing internet connection "
  ping -q -c 1 -W 1 google.com >/dev/null 2>&1 && echo "- OK" || { echo "Error"; false; }
}

# Log files will be uploaded to termbin.com
# Logs included: VERLOG LOG oldVERLOG oldLOG
upload_logs() {
  $BBok && {
    test_connection || exit
    echo "Uploading logs"
    [ -s $VERLOG ] && verUp=$(cat $VERLOG | nc termbin.com 9999) || verUp=none
    [ -s $oldVERLOG ] && oldverUp=$(cat $oldVERLOG | nc termbin.com 9999) || oldverUp=none
    [ -s $LOG ] && logUp=$(cat $LOG | nc termbin.com 9999) || logUp=none
    [ -s $oldLOG ] && oldlogUp=$(cat $oldLOG | nc termbin.com 9999) || oldlogUp=none
    echo -n "Link: "
    echo "$MODEL ($DEVICE) API $API\n$ROM\n$ID\n
    O_Verbose: $oldverUp
    Verbose:   $verUp

    O_Log: $oldlogUp
    Log:   $logUp" | nc termbin.com 9999
  } || echo "Busybox not found!"
  exit
}

# Print Random
# Prints a message at random
# CHANCES - no. of chances <integer>
# TARGET - target value out of CHANCES <integer>
prandom() {
  local CHANCES=2
  local TARGET=2
  [ "$1" ==  "-c" ] && { local CHANCES=$2; local TARGET=$3; shift 3; }
  [ "$((RANDOM%CHANCES+1))" -eq "$TARGET" ] && echo "$@"
}

# Print Center
# Prints text in the center of terminal
pcenter() {
  local CHAR=$(echo $@ | sed 's/\\e[[0-9;]*m//g' | wc -m)
  local hfCOLUMN=$((COLUMNS/2))
  local hfCHAR=$((CHAR/2))
  local indent=$((hfCOLUMN-hfCHAR-1))
  echo "$(printf '%*s' "${indent}" '') $@"
}

# Heading
mod_head() {
  clear
  echo "$div"
  echo "${W}$MODTITLE $VER${N}(${Bl}$REL${N})"
  echo "by ${W}$AUTHOR${N}"
  echo "$div"
  echo "${W}$_bbname${N}"
  echo "${Bl}$_bb${N}"
  echo "$div"
  [ -s $LOG ] && echo "Enter ${W}logs${N} to upload logs" && echo $div
}
