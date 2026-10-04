# level14

The final boss. No home-dir binary, no helpful file, nothing owned by flag14. The target this time is `getflag` itself, the program that's been handing out tokens the whole way up. Turns out it's paranoid :)

| | |
| --- | --- |
| **Login** | `level14` / `2A31L79asukciNyi8uppkEuSx` (the level13 token) |
| **flag14 token** | `7QiHafiNa3HVozsaXkawuYrTstxbpABHD8CPnHJ` |


## poking around

Home is empty, `find / -user flag14` finds nothing. The only lead is `/bin/getflag` (owned root, not setuid, world-readable). So we reverse it.

## what getflag actually does

Disassembling `main`:

1. `ptrace(PTRACE_TRACEME, ...)` and check the result. If it's already being traced (return < 0), print a message and quit. **Anti-debugger.**
2. `getenv("LD_PRELOAD")`. If set, print `Injection Linked lib detected exit..` and quit. **Anti-preload.** (This is what killed our first attempt.)
3. Open and scan `/proc/self/maps` (`isLib` / `afterSubstr`) looking for an injected library. **Anti-preload again,** in case you hid the env var.
4. Call `getuid()`, then a big switch: `0xbb8`..`0xbc6` (3000..3014) are the flag UIDs. Each case passes an encrypted blob to `ft_des()` and prints the result. `0xbc6` = 3014 = flag14.

So getflag already contains every flag's token, encrypted, and just decrypts the one matching your UID. Our job is to make it decrypt flag14's.

## the runtime guards, and why they're not enough

- `LD_PRELOAD` to fake `getuid()` -> caught by checks (2) and (3).
- `gdb` to force `getuid()`'s return -> check (1) *tries* to stop you: `ptrace(TRACEME)` returns -1 under gdb (gdb is already the tracer), and getflag bails on that. But that check is just an instruction you're sitting on top of. Break right after the `ptrace` call and spoof its return before getflag reads it, and the anti-debug is defused like any other.

So gdb works fine, you just have to lie to it. First you tell it `ptrace` succeeded. Then you tell it you're flag14. Next you're gonna tell it Santa exists.

## route A: gdb, spoof both returns

`0x804898e` is the `test eax, eax` right after `call ptrace` (force `eax` >= 0), and `0x8048b02` is right after `call getuid` (force `eax` = `0xbc6` = 3014):

```
break *0x804898e
break *0x8048b02
run
set $eax = 0        # ptrace "succeeded", anti-debug passes
continue
set $eax = 0xbc6    # getuid() "returns" flag14's uid
continue
```

```bash
$ gdb -q -batch -x g14 /bin/getflag
Check flag.Here is your token : 7QiHafiNa3HVozsaXkawuYrTstxbpABHD8CPnHJ
```

The `g14` command file is in this folder. LD_PRELOAD and the maps scan don't fire here because we inject nothing, we just edit two registers mid-run.

## route B: patch a copy (no debugger at all)

The token is baked into the binary and `ft_des()` needs no privileges, so we don't even have to run the real, protected process. Copy getflag (the copy is ours, non-setuid) and patch the decision point directly.

At `0x8048afd` the code is `call getuid@plt` (`e8 ae f9 ff ff`, 5 bytes), and its result drives the switch. Replace it with `mov eax, 0xbc6` (`b8 c6 0b 00 00`, also 5 bytes). Now `getuid()` is never called, `eax` is just hard-wired to flag14's UID, and the switch walks straight into the flag14 case.

```bash
$ cp /bin/getflag /tmp/gf
$ python2 patch.py            # overwrites the call with mov eax, 0xbc6
$ /tmp/gf
Check flag.Here is your token : 7QiHafiNa3HVozsaXkawuYrTstxbpABHD8CPnHJ
```

The three guards (ptrace, LD_PRELOAD, maps scan) all pass, because we're running a clean copy with no debugger and no preload. They were guarding the UID check, and we never touched the UID check, we replaced it. `patch.py` in this folder is the patcher.

## done

That's level14, and the end of Snow Crash. 15 for 15.
