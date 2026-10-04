# Snow Crash

*"t'as regardé ta trace?"*

A 42 security project: fifteen little boxes (level00 through level14), each locked
with a different war crime from the history of computing. Plaintext passwords in a
packet capture. A setuid binary that trusts `$PATH` like it's a pinky promise.
`preg_replace` with the `/e` flag, which PHP shipped on purpose, with a straight
face, and has since spent a decade pretending it never happened. You log in, you
find the flag account's password through whatever sin the level was built around,
you run `getflag`, and the token it coughs up is the next level's password. Then
you do it fourteen more times and quietly uninstall your trust in software.

The whole thing runs off a live ISO in a VM that forgets everything the second it
reboots, the digital equivalent of a goldfish with commitment issues. So every
answer worth keeping sprints out into this repo before the VM can take it to the
grave out of spite.

## quickstart

```bash
make vm          # grab the SnowCrash ISO and boot it headless, sshd on localhost:4242
make toolbox     # boot a Debian box with every tool we used (john, tshark, gdb, ...), minus IDA
make toolbox-ssh # drop into the toolbox; the repo is already sitting at ~/snowcrash, you're welcome
```

From inside the toolbox the target answers through the host, because qemu's gateway
cheerfully forwards your packets right back where they came from, no questions asked
(a recurring theme around here):

```bash
ssh -p 4242 level00@10.0.2.2     # the password is level00, they trusted you exactly once
```

Then open `level00/resources/walkthrough.md` and start climbing. Every walkthrough
hands you the keys to the next door. Spoiler: no door is locked half as well as its
owner assumes.

## make targets

`make help` has the full list. The highlights:

| target | does |
| --- | --- |
| `make vm` | boot the SnowCrash ISO (the victim) |
| `make vm-gui` | same, but with a window, for when you want to watch it boot like it's 2013 |
| `make ssh` | ssh into the target (`LEVEL=levelXX` to pick your poison) |
| `make vm-stop` / `make vm-destroy` | pull the plug / salt the earth |
| `make toolbox` | boot the attacker box and sync this repo into it |
| `make toolbox-ssh` | shell into the toolbox, lands you in `~/snowcrash` |
| `make toolbox-sync` | re-push the repo after you inevitably change something |
| `make toolbox-destroy` | shred the toolbox (the base image lives; 350 MiB is a long walk back) |

VM storage lands in `/goinfre/$USER` (or `$TMPDIR`), never your home, because a few
GB of VM versus a 5 GB quota is a hostage situation, and the Makefile refuses to be
the one holding the gun.

## layout

```
levelXX/
  flag                  the token getflag coughed up (= level XX+1's password)
  resources/
    walkthrough.md      how we got in, start to finish, dead ends trimmed out
    <scripts>           the exploit, when one was worth keeping
```

The subject forbids committing binaries or anything looted off the ISO, so the
level binaries, the pcap, the perl/lua scripts, and the ISO are all absent, left at
the scene of the crime like responsible adults. The walkthroughs quote what they
need and tell you to `scp` the rest live while the evaluator pretends not to watch.
The Makefile re-downloads the ISO on demand instead of smuggling it into git.

## reproducing

The tokens are baked into the ISO, so they're byte-identical on every boot, the box
has the imagination of a brick. The entire chain has been re-solved end to end
against a freshly booted VM, every exploit fired for real, every token diffed
against its `flag` file: 15 for 15, no asterisks. If yours come out different, the
bug is on your side of the keyboard, and the walkthroughs will gently prove it.
