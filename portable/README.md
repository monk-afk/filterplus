## Chat Filter -- Development Files

Filter blacklisted words with associative table.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023, Licensed under CC0</sup>

##
This incomplete module provides a functional starting point for a chat/message filter.

"***Positive Match***" uses string.match for exact words after sanity substitutions.  It removes extra whitespace and padding, non-alphabet characters, duplicate letters, and joins gapped words.  Single-character words are ignored.  Then find index pair in blacklist using suffix -> prefix -> word.

Example of Suffix->Prefix table structre:
```lua
k = { m = { "monk" },
      l = { "link" } },
e = { f = { "face", "frostbite" } }
```

"***Potential Match***" traverses the entire blacklist to find words in the input string stripped of all non-alphabetic characters including spaces. This function is enabled and is only included for research or development.

##

**Benchmark**

Intel(R) Core(TM) i3-1005G1 CPU @ 1.20GHz
> small_log.txt (1.6M)
```
Potentials enabled,		|	Potentials disabled,
line count: 100000		|	line count: 100000
word count: 246021		|	word count: 246021
black list: 12			|	black list: 12
filter hit: 16			|	filter hit: 16
potentials: 64			|	potentials: 0
clock time: 1.327554		|	clock time: 1.044904
```
> large_logfile.txt (16M)
```
Potentials enabled,		|	Potentials disabled,
line count: 1000000		|	line count: 1000000
word count: 2384993		|	word count: 2384993
black list: 12			|	black list: 12
filter hit: 63			|	filter hit: 63
potentials: 407			|	potentials: 0
clock time: 13.267387		|	clock time: 9.918169
```

##

**dev_0.02**