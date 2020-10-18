#!/bin/bash
source gblw210_rc
make -j24 && \
  rm -f 210.bin && \
  ./mkmini210 u-boot.bin 210.bin
