#!/bin/sh

rm file_index.txt 2> /dev/null
touch file_index.txt > /dev/null
find app -type f > file_index.txt
find lib -type f >> file_index.txt
echo "VERSION" >> file_index.txt
echo "start.lua" >> file_index.txt
echo "file_index.txt updated!"