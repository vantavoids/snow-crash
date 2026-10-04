# level10

First bonus level, and it's the classic race condition: the program checks your permission and then opens the file, and in the gap between those two steps we swap the file out from under it. Security theater with a timing bug :)

| | |
| --- | --- |
| **Login** | `level10` / `s5cAJpM8ev6XHw998pRWG728z` (the flag09 token) |
| **flag10 password** | `woupa2yuojeeaaed06riuj63c` (raced out of the `token` file) |
| **flag10 token** | `feulo4b72j7edeahuete3no7c` (aka the level11 password) |

## poking around

A setuid binary, a `token` file we can't read, and the binary tells you its job:

```bash
$ ~/level10
./level10 file host
	sends file to host if you have access to it
```

```bash
$ ls -l ~
-rwsr-sr-x+ 1 flag10 level10 10817 ... level10
-rw-------  1 flag10 flag10     26 ... token      # flag10 only
```

So it sends a file to a host, *if you have access to it*. The catch is how it checks "if you have access".

## the bug (TOCTOU)

`strings`/IDA show the sequence: `access(file, R_OK)` then `open(file)` then `connect` to `host:6969` and send the contents.

- `access()` checks permissions against the **real** uid (level10), so it's the program being polite: "can *you* read this?"
- `open()` runs with the **effective** uid (flag10), which can read anything.

Between the check and the open there's a window. If `file` is a symlink, we can make `access()` see one target and `open()` see another. This is TOCTOU: time-of-check to time-of-use.

## winning the race

The plan:

1. A dummy file we own (passes `access`).
2. A symlink that we flip, as fast as possible, between the dummy and `~/token`.
3. A listener on port 6969 to catch whatever gets sent.
4. Run the binary over and over.

Most runs lose (it opens the dummy, or `access` fails on the token). But eventually the stars align: `access()` fires while the link points at the dummy (pass), then the link flips to `token` before `open()`, and flag10 happily ships us the token.

```bash
$ sh race.sh
woupa2yuojeeaaed06riuj63c
```

`race.sh` in this folder runs all three loops for ~55s and filters the listener output down to the one line that isn't the dummy or the server's `.*( )*.` banner. On a quiet box it usually wins within a few seconds. That string is flag10's password.

## finishing the job

```bash
$ su flag10          # password: woupa2yuojeeaaed06riuj63c
$ getflag
Check flag.Here is your token : feulo4b72j7edeahuete3no7c
```
