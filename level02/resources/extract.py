#!/usr/bin/env python3
# reassemble the client-typed keystrokes from level02's telnet capture
# fetch the pcap live at eval time (it lives on the ISO, never committed):
#   scp -P 4242 level02@<vm>:/home/user/level02/level02.pcap .
# then feed it the client->server bytes:
#   tshark -r level02.pcap -Y 'ip.src==59.233.235.218 && tcp.len>0' \
#          -T fields -e data | tr -d '\n' | python3 extract.py
import sys

h = sys.stdin.read().strip()
b = bytes.fromhex(h)

# telnet carries option negotiation inline as IAC (0xff) sequences that we don't care about. drop them:
# IAC SB ... IAC SE is a variable-length subnegotiation, everything else is
# IAC + command + option (3 bytes).
out = bytearray()
i = 0
while i < len(b):
    if b[i] == 0xff:
        if i + 1 < len(b) and b[i + 1] == 0xfa:      # SB, read until IAC SE
            j = i + 2
            while j + 1 < len(b) and not (b[j] == 0xff and b[j + 1] == 0xf0):
                j += 1
            i = j + 2
        else:
            i += 3
    else:
        out.append(b[i])
        i += 1

# replay the line as the terminal saw it: 0x7f is a destructive backspace
typed = bytearray()
for c in out:
    if c == 0x7f:
        if typed:
            typed.pop()
    else:
        typed.append(c)

print("raw  :", repr(bytes(out)))
print("typed:", repr(bytes(typed)))
