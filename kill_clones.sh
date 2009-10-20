#!/bin/sh

NGCTL="/usr/sbin/ngctl"
GREP="/usr/bin/grep"
AWK="/usr/bin/awk"

NGTYPE="eiface"

for cloneif in `$NGCTL list | $GREP $NGTYPE | $AWK '{print $2;}'`; do
  $NGCTL shutdown $cloneif:
done


