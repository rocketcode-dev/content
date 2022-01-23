## Cheat notes: Extended Globbing

Standard Globbing:

* `*`	Matches zero or more characters
* `?`	Matches any single character
* `[...]`	Matches any of the characters in a set

Extended Globbing:

* `?(patterns)`	Matches zero or one occurrences of the patterns
* `*(patterns)`	Matches zero or more occurrences of the patterns
* `+(patterns)`	Matches one or more occurrences of the patterns
* `@(patterns)`	Matches one occurrence of the patterns
* `!(patterns)`	Matches anything that doesn't match one of the patterns

Patterns can else be combined with `|`

To enable extended globbing
```shell
# enable extended globbing
$> shopt -s extglob

# disable extended globbing
$> shopt -u extglob

# query if extended globbing is on
$> shopt -q extglob
$> echo $?
```

Example

```shell
# to match both `package.json` and `package-lock.json` (both examples work)
$> ls @(package|package-lock).json
$> ls package?(-lock).json
```
