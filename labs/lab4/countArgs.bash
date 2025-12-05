#!/bin/bash

# Trevor Thompson tthompso
# Andrew Lam Ho alh24

case $# in
  0) exit 1 ;;
  1) exit 2 ;;
  2) exit 0 ;;
  *) exit 3 ;;
esac