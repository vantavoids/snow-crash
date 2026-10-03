#!/usr/bin/env python3
# level09: the token file is readable but each byte was shifted up by its
# position index (byte[i] += i). Undo it with byte[i] - i.
#   cat ~/token | python3 decode.py
import sys
data = sys.stdin.buffer.read().rstrip(b"\n")
print("".join(chr(b - i) for i, b in enumerate(data)))
