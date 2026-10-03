# level00

The tutorial level. The one where the game holds your hand and the training wheels are still on, and somehow you can still faceplant :)

| | |
| --- | --- |
| **Login** | `level00` / `level00` |
| **flag00 password** | `nottoohardhere` |
| **flag00 token** | `x24ti5gi3x0ol2eh4esiuxias` (aka the level01 password, you're welcome) |

## poking around

Logged in, looked at home, found three dotfiles and crushing emptiness. Classic. The box is clearly hiding the good stuff under someone else's name, so let's go snooping where we don't belong:

```bash
find / -user flag00 2>/dev/null
```

One file worth caring about (the `/rofs` twin is just the live ISO's read-only clone, ignore it):

```
/usr/sbin/john
```

A file named `john`, owned by `flag00`, chilling in `/usr/sbin` like it pays rent there, world-readable because why not. Discretion: zero.

```bash
$ cat /usr/sbin/john
cdiiddwpgswtgt
```

## the bait

The name is screaming JOHN THE RIPPER at you, which is the whole joke, because you don't have a hash, you have 14 sad little lowercase letters. Throw that at John and congratulations, you've just donated an afternoon to charity.

Squint at it next to something English-shaped and the disguise falls off, repeats stay repeats:

```
c d i i d d w p g s w t g t
n o t t o o h a r d h e r e
```

`ii` to `tt`, `dd` to `oo`, the `w`s to `h`s, the `g`s to `r`s. It's a baby substitution cipher wearing a trenchcoat, and it spells **`nottoohardhere`**. The file basically rats itself out.

## grabbing the loot

```bash
$ su flag00          # password: nottoohardhere
$ getflag
Check flag.Here is your token : x24ti5gi3x0ol2eh4esiuxias
```

gg, one down :)
