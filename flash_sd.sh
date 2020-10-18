#!/bin/bash
if [ "$1" == "" ]; then echo "Usage: $0 <device>"; exit 1; fi
while :
do
  ls $1
  if [ $? -eq 0 ]
  then
    break
  fi
  sleep 1
done
dd iflag=dsync oflag=dsync if=210.bin of=$1 seek=1
dd iflag=dsync oflag=dsync if=u-boot.bin of=$1 seek=49
