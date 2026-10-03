# level02

The password isn't hidden here. Someone just used telnet, so the network photocopied their keystrokes on the way past. Encryption is a lifestyle, people :)

| | |
| --- | --- |
| **Login** | `level02` / `kooda2puivaav1idi4f57q8iq` (the flag01 token) |
| **flag02 password** | `ft_waNDReL0L` |
| **flag02 token** | `kooda2puivaav1idi4f57q8iq` (aka the level03 password) |

## poking around

Home has exactly one thing worth a second look, owned by flag02 and readable by us:

```bash
$ file ~/level02.pcap
level02.pcap: tcpdump capture file ...
```

A packet capture, left somewhere we can read it. `find / -user flag02` turns up nothing else, so the whole level is inside this file.

## reading the capture

The pcap is binary and lives on the ISO, so it stays out of the repo. Pull it live instead:

```bash
scp -P 4242 level02@<vm>:/home/user/level02/level02.pcap .
```

One glance tells you what it is:

```bash
$ tcpdump -nr level02.pcap | head
... 59.233.235.218.39247 > 59.233.235.223.12121 ...
```

A session to port 12121 where the client sends a stream of 1-byte packets and the server echoes each back as 2 bytes. That is interactive telnet to the letter: every keystroke is its own packet and the server echoes it so your terminal can display it. The login and password were typed one plaintext character at a time, in full view of anyone on the wire. Follow the stream and the server's bytes spell the prompts (`wwwbugs login:`, `Password:`) while the client's bytes are the typing.

## the backspace trap

Take just the client-to-server bytes, strip the telnet `0xff` negotiation noise, and you get:

```
levelX\r  ft_wandr \x7f\x7f\x7f NDRel \x7f L0L \r
```

You can't read this left to right, because `0x7f` is DEL, a destructive backspace, and the typist fat-fingered it on purpose (like if they made the worst subjects of the whole common core). Replay it the way the terminal did:

- `ft_wandr`
- three backspaces eat `r`, `d`, `n` -> `ft_wa`
- `NDRel` -> `ft_waNDRel`
- one backspace drops the `l` -> `ft_waNDRe`
- `L0L` -> `ft_waNDReL0L`

Password: **`ft_waNDReL0L`**. The `extract.py` in this folder does the IAC-stripping and the backspace replay so you don't have to do it by hand.

## grabbing the loot

```bash
$ su flag02          # password: ft_waNDReL0L
$ getflag
Check flag.Here is your token : kooda2puivaav1idi4f57q8iq
```

Three down :)
