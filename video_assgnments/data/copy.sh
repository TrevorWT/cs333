#!/bin/bash

for f in v?.txt; do
  [ -L "$f" ] && tgt="$(readlink -f -- "$f")" && /bin/cp -p -- "$tgt" "$f.tmp" && mv -f -- "$f.tmp" "$f"
done

ls -l v?.txt   # no "->" arrows now
file v?.txt    # should say "text", not "symbolic link"