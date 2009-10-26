#!/bin/sh

NGCTL="/usr/sbin/ngctl"
GREP="/usr/bin/grep"
AWK="/usr/bin/awk"

NGTYPE="eiface"
BRDG="nbridge0"

if [ -n "$1" ]; then
  BRDG=$1	
fi

for cloneif in `$NGCTL list | $GREP $NGTYPE | $AWK '{print $2;}'`; do
  $NGCTL shutdown $cloneif:
done

$NGCTL shutdown $BRDG:
