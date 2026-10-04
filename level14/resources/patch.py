#!/usr/bin/env python2
# because we learnt from previous mistakes

off = 0x8048afd - 0x8048000
f = bytearray(open("/tmp/gf", "rb").read())
assert f[off:off+5] == b"\xe8\xae\xf9\xff\xff", "unexpected bytes, did someone mess up their offsets :P?"
f[off:off+5] = b"\xb8\xc6\x0b\x00\x00"   # mov eax, 0xbc6
open("/tmp/gf", "wb").write(f)
print("patched :D")
