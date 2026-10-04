# level02

The password isn't hidden here. Someone just used telnet, so the network photocopied their keystrokes on the way past. Encryption is a lifestyle, people :)

| | |
| --- | --- |
| **Login** | `level02` / `f2av5il02puano7naaf6adaaf` (the flag01 token) |
| **flag02 password** | `ft_waNDReL0L` |
| **flag02 token** | `kooda2puivaav1idi4f57q8iq` (aka the level03 password) |

## poking around

Home has exactly one thing worth a second look, owned by flag02 and readable by us:

```bash
$ file ~/level02.pcap
level02.pcap: tcpdump capture file ...
```

A packet capture, left somewhere we can read it. `find / -user flag02` turns up nothing else, so the whole level is inside this file.

## step 1: copy the pcap to a machine with analysis tools

The pcap is binary and lives on the ISO, so it stays out of the repo, and the target has no tshark anyway. Copy it to the toolbox VM (or any box with wireshark/tshark). From the toolbox the target is reachable through the host at `10.0.2.2:4242`:

```bash
scp -P 4242 level02@10.0.2.2:/home/user/level02/level02.pcap .
chmod u+r level02.pcap     # scp sometimes drops owner-read, chmod if you can't open it
```

## step 2: see what the capture is

```bash
$ tcpdump -nr level02.pcap | head
07:23:12 IP 59.233.235.218.39247 > 59.233.235.223.12121: Flags [S] ...
```

A session to port 12121 where the client (`59.233.235.218`) sends a stream of 1-byte packets and the server (`...223`) echoes each back as 2 bytes. That is interactive telnet to the letter: every keystroke is its own packet, echoed so your terminal can display it. The login and password were typed one plaintext character at a time, in full view of anyone on the wire. Follow the stream (`tshark -q -z follow,tcp,hex,0 -r level02.pcap`) and the server's bytes spell the prompts (`wwwbugs login:`, `Password:`) while the client's bytes are the typing.

## step 3: recover the password (mind the backspaces)

Pull just the client-to-server bytes and run them through `extract.py`, which strips the telnet `0xff` negotiation noise and replays the keystrokes:

```bash
$ tshark -r level02.pcap -Y 'ip.src==59.233.235.218 && tcp.len>0' -T fields -e data \
    | tr -d '\n' | python3 extract.py
raw  : b'levelX\rft_wandr\x7f\x7f\x7fNDRel\x7fL0L\r'
typed: b'levelX\rft_waNDReL0L\r'
```

The `raw` line is why you can't just read it off: `0x7f` is DEL, a destructive backspace, and the typist fat-fingered it on purpose (like if they made the worst subjects of the whole common core). Replayed the way the terminal saw it:

- `ft_wandr`
- three backspaces eat `r`, `d`, `n` -> `ft_wa`
- `NDRel` -> `ft_waNDRel`
- one backspace drops the `l` -> `ft_waNDRe`
- `L0L` -> `ft_waNDReL0L`

So flag02's password is **`ft_waNDReL0L`**.

## step 4: become flag02 and get the token

The pcap only gave us the password, not the token, and that password is flag02's on the *target*, not on the box you ran tshark on. Back on the target (where you're logged in as level02), switch user and run getflag:

```bash
level02@SnowCrash:~$ su flag02      # password: ft_waNDReL0L
flag02@SnowCrash:~$ getflag
Check flag.Here is your token : kooda2puivaav1idi4f57q8iq
```

Three down :)
