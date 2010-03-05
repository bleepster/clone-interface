#!/bin/sh

NGCTL="/usr/sbin/ngctl"
IFCONFIG="/sbin/ifconfig"
RM="/bin/rm -f"
TOUCH="/usr/bin/touch"
CAT="/bin/cat"
SED="/usr/bin/sed"
HEAD="/usr/bin/head"
SHA256="/sbin/sha256"
DEVRANDOM="/dev/random"
GREP="/usr/bin/grep"
XARGS="/usr/bin/xargs"
AWK="/usr/bin/awk"

BRDG="nbridge0"
NGCMD_FILE="./ngcmd.file"
MACGEN_FILE="./macgen.file"
IFCLONE="ifclone"

if [ -n "$1" ]; then
else
  echo "usage: ./clone_if.sh <interface> <max number of clones> <bridge name>"
  exit
fi

if [ -n "$2" ]; then
else
  echo "usage: ./clone_if.sh <interface> <max number of clones> <bridge name>"
  exit
fi

if [ -n "$3" ]; then
  BRDG=$3
fi

PHYS_IF=$1
MAX_CLONES=$2

## snippet from /usr/share/examples/netgraph/ether.bridge ##
for KLD in ng_ether ng_eiface ng_bridge; do
  if kldstat -v | grep -qw ${KLD}; then
  else
    echo -n "Loading ${KLD}.ko... "
    kldload ${KLD} || exit 1
    echo "done"
  fi
done
echo "modules loaded"

## temporarily put down physical interface ##
${IFCONFIG} ${PHYS_IF} delete
## special case for IPv6 address
${IFCONFIG} ${PHYS_IF} | ${GREP} inet6 | ${AWK} '{print $2}' | ${XARGS} -I addr\
  ${IFCONFIG} ${PHYS_IF} inet6 addr delete
${IFCONFIG} ${PHYS_IF} down
echo "physical interface brought down"

## create ng_bridge node ##
## attach it to the physical interface's ng_ether node ##
LNUM=0
${NGCTL} mkpeer ${PHYS_IF}: bridge lower link${LNUM} || exit 1
${NGCTL} name ${PHYS_IF}:lower ${BRDG} || exit 1
LNUM=$(($LNUM+1))
echo "bridge created"
echo "physical interface's ng_ehter node attached to the bridge"

${RM} ${NGCMD_FILE}
${TOUCH} ${NGCMD_FILE}

## attach ng_eiface nodes to the ng_bridge node ##
COUNT=0
while [ ${COUNT} -lt ${MAX_CLONES} ]; do
  echo "mkpeer ${BRDG}: eiface link${LNUM} ether" >> ${NGCMD_FILE}
  echo "name ${BRDG}:link${LNUM} ${IFCLONE}${LNUM}" >> ${NGCMD_FILE}
  LNUM=$(($LNUM+1))
  COUNT=$(($COUNT+1))
done

${CAT} ${NGCMD_FILE} | ${NGCTL} -f- || exit 1
${RM} ${NGCMD_FILE}
echo "clones created"

## configure the physical interface's ng_ether node ##
${NGCTL} msg ${PHYS_IF}: setautosrc 0 || exit 1
${NGCTL} msg ${PHYS_IF}: setpromisc 1 || exit 1
echo "physical interface configured"

${RM} ${MACGEN_FILE}
${TOUCH} ${MACGEN_FILE}

## generate random MAC addresses ##
MACCOUNT=0
while [ ${MACCOUNT} -lt ${MAX_CLONES} ]; do
  ${HEAD} ${DEVRANDOM} | ${SHA256} | \
  ${SED} -E 's/^(.{12}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'	>> \
  ${MACGEN_FILE}
  MACCOUNT=$(($MACCOUNT+1))
done
echo "MAC addresses generated"

## assign unique (hopefully)  MAC addresses for each ngeth(N) interface ##
## UP all ngeth(N) interfaces ##
COUNT=0
if [ -r ${MACGEN_FILE} ]; then
  while read line; do
    $IFCONFIG ngeth${COUNT} link $line || exit 1
    $IFCONFIG ngeth${COUNT} up || exit 1
    COUNT=$(($COUNT+1))
  done < ${MACGEN_FILE}
fi
echo "clones UP and running"

${RM} ${MACGEN_FILE}

## UP physical interface ##
${IFCONFIG} ${PHYS_IF} up || exit 1
echo "physical interface up and running"
