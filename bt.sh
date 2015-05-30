#!/bin/bash

set -ue

HANG_PID=$1

show() {
  echo "===> $@"
  $@
  echo ""
}

show uname -a
show perl -V
show gdb --batch -p $HANG_PID -x gdb-command.txt
