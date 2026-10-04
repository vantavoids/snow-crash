# level13

A binary with a bouncer: it checks your UID at the door and will only talk to user 4242, who does not exist. So we lie about who we are :)

| | |
| --- | --- |
| **Login** | `level13` / `g1qKMiRpXf53AWhDaU7FEkczr` (the flag12 token) |
| **flag13 password** | n/a (the binary prints the token itself) |
| **token (level14 password)** | `2A31L79asukciNyi8uppkEuSx` |

Note: level13 breaks the pattern. There's no `getflag` and no flag13 login, the binary just prints the next token directly once you get past its UID check.

## poking around

One setuid binary, and it tells you exactly why it won't cooperate:

```bash
$ ~/level13
UID 2013 started us but we we expect 4242
```

`strings` confirms the logic:

```
getuid
UID %d started us but we we expect %d
your token is %s
```

So: it calls `getuid()`, compares to 4242, and if you're not 4242 it bails. If you are, it prints `your token is ...`. The token is baked into the binary, it just gates it behind that check.

## the problem

`getuid()` returns your **real** UID, which is 2013 (level13). No account on the box has UID 4242, so we can't just "become" 4242 by logging in as someone.

## the lie

We replace `getuid()` with our own version that returns 4242, using `LD_PRELOAD` to load our library ahead of libc:

```c
int getuid(void) { return 4242; }
```

One catch: the dynamic loader **ignores** `LD_PRELOAD` for setuid binaries (otherwise every setuid program would be trivially hijackable). So we run a non-setuid copy instead. That's fine here, because the token lives inside the binary, it doesn't need flag13's privileges to be printed, only the UID check standing in the way.

`gu.c` in this folder is the override. It compiles against the target's 32-bit libc, so build and run it on the target. From the toolbox, copy the source over and log in:

```bash
scp -P 4242 ~/snowcrash/level13/resources/gu.c level13@10.0.2.2:/tmp/
ssh -p 4242 level13@10.0.2.2        # password: g1qKMiRpXf53AWhDaU7FEkczr
```

Then on the target:

```bash
$ gcc -shared -fPIC -o /tmp/gu.so /tmp/gu.c
$ cp ~/level13 /tmp/l13
$ LD_PRELOAD=/tmp/gu.so /tmp/l13
your token is 2A31L79asukciNyi8uppkEuSx
```

Our fake `getuid` answers 4242, the bouncer waves us through, and the binary reads out the token.
