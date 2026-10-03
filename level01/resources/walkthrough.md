# level01

Someone left the password lying in `/etc/passwd`. Encrypted, sure, but with 1970s crypto, so it's less "locked away" and more "locked in a diary with a tiny brass clasp" :)

| | |
| --- | --- |
| **Login** | `level01` / `x24ti5gi3x0ol2eh4esiuxias` (the flag00 token) |
| **flag01 password** | `abcdefg` |
| **flag01 token** | `f2av5il02puano7naaf6adaaf` (aka the level02 password) |

## poking around

`find / -user flag01` turns up nothing this time, so the goodies aren't a stray file. But look at the guest list:

```bash
$ grep flag01 /etc/passwd
flag01:42hDRfypTqqnw:3001:3001::/home/flag/flag01:/bin/bash
```

That second field should be an `x` (meaning "password's in `/etc/shadow`, mind your business"). Instead it's `42hDRfypTqqnw`, a raw password hash sitting in a world-readable file like it's no big deal. It's 13 characters, which is the universal fingerprint of traditional DES `crypt(3)`: 2 chars of salt (`42`) + 11 of hash. Ancient, weak, crackable over a coffee break.

## cracking it

This is the level that's actually about John the Ripper (unlike level00, which only name-dropped it to mess with you). Pull that line into a file and set John loose:

```bash
$ echo 'flag01:42hDRfypTqqnw:3001:3001::/home/flag/flag01:/bin/bash' > hash.txt
$ john --format=descrypt hash.txt
...
abcdefg          (flag01)
```

Instant. `abcdefg` is in every wordlist ever shipped, so John's default run snaps it up before you've let go of Enter. The password is **`abcdefg`**.

(Side note: cracked this on the host because the VM is a live ISO with no real John on it. At the eval you download `/etc/passwd` with `scp` and crack it on your own machine, exactly the same move.)

## grabbing the loot

```bash
$ su flag01          # password: abcdefg
$ getflag
Check flag.Here is your token : f2av5il02puano7naaf6adaaf
```

Two down :)
