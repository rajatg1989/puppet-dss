#!/bin/bash

if [ $# -gt 0 ]; then
  case $1 in
    -h|--help|help)
      cat << __EOH__
$0 - To test timezone
------------------------
  This script verify timezone is correctly set.

Parameters:
-----------
-t <timezone>   where <timezone> is alphabetic timezone abbreviation (e.g, IST)
__EOH__
       ;;
    -t)
      timezone=$2
      ;;
   esac
fi

timezone=${timezone:-'IST'}
current_tz=`date +%Z`
if [ `echo $current_tz | grep -c $timezone` -ne 0 ]; then
  echo "OK: timezone is set to $timezone"
  exit 0
else
  echo "CRITICAL: Wrong timzone set. Current timezone is $current_tz"
  exit 2
fi
