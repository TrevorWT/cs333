#!/bin/bash
set -euo pipefail

mkdir -p ./out
input="-i ./passwords-10.txt"
dictionary="-d ./hashes-10.txt"

hisProg="./thread_hash"
hisOut="./out/his.out"
hisErr="./out/his.err"

myProg="./thread_hash"
myOut="./out/my.out"
myErr="./out/my.err"

$hisProg $dictionary $input 2> $hisOut > $hisErr
$myProg $dictionary $input 2> $myOut > $myErr

diff -u $hisOut $myOut > ./out/diff.out

sort $hisErr > ./out/his.sorted.err
sort $myErr > ./out/my.sorted.err

diff -u ./out/his.sorted.err ./out/my.sorted.err >> ./out/diff.out

for f in ./out/*.out; do
    if [ ! -s "$f" ]; then
     rm -- "$f"
    fi
done