# level09

The last mandatory level, and it goes out on "we encrypted the token" where "encrypted" means "added a little to each letter". Caesar would be disappointed, and he's been dead for 2000 years :)

| | |
| --- | --- |
| **Login** | `level09` / `25749xKZ8L7DkSCwJkT9dyv6f` (the flag08 token) |
| **flag09 password** | `f3iji1ju5yuevaus41q1afiuq` (decoded from the `token` file) |
| **flag09 token** | `s5cAJpM8ev6XHw998pRWG728z` (aka the level10 password) |

## poking around

A setuid binary and a `token` file, and this time we can actually read the token:

```bash
$ ls -l ~
-rwsr-sr-x 1 flag09 level09 7640 ... level09
----r--r-- 1 flag09 level09   26 ... token     # r--r--, we can read it
$ cat ~/token
f4kmm6p|=...   # garbage
```

It's readable but scrambled. The `level09` binary is the encoder that made it, so reversing the binary tells you the scheme. (You don't even strictly need the binary, the pattern is guessable, but it confirms it.)

## the scheme

Each byte of the plaintext was shifted up by its **position**: byte 0 unchanged, byte 1 `+1`, byte 2 `+2`, and so on. That's why the start looks almost normal (`f`, then `4` which is `3+1`...) and it drifts further off as it goes.

Looking at the hex, the first bytes are `66 34 6b 6d ...`:

- `0x66 - 0 = 0x66` -> `f`
- `0x34 - 1 = 0x33` -> `3`
- `0x6b - 2 = 0x69` -> `i`
- `0x6d - 3 = 0x6a` -> `j`
- ...

## decoding it

`decode.py` in this folder does the subtraction. The token is world-readable, so you can decode it right on the target, copy the script over from the toolbox:

```bash
scp -P 4242 ~/snowcrash/level09/resources/decode.py level09@10.0.2.2:/tmp/
ssh -p 4242 level09@10.0.2.2        # password: 25749xKZ8L7DkSCwJkT9dyv6f
```

Then subtract the index from every byte (ignoring the trailing newline):

```bash
$ cat ~/token | python3 /tmp/decode.py
f3iji1ju5yuevaus41q1afiuq
```

That string is flag09's password.

## finishing the job

```bash
$ su flag09          # password: f3iji1ju5yuevaus41q1afiuq
$ getflag
Check flag.Here is your token : s5cAJpM8ev6XHw998pRWG728z
```

Mandatory part complete. level10 onward is bonus.
