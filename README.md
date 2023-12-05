# Chat Filter

<sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023, Licensed under CC0</sup>

##
## About

**Chat Filter** uses a suffix->prefix->word trie. Much faster than matching whole words from a wordlist. This module is not complete, it only provides enough for a functional codebase.

Filter method: Remove extra whitespace and padding, remove non-alphabet characters, merge gapped words, then remove duplicate letters.  The string is then split into individual words.  Single-character words are ignored.  Cross-reference word suffix, then prefix, with the similarly indexed wordlist; example: [m]on[k] suffix and prefix matches [m]in[k].  If a match is found, the word is checked against the returned keys.

The evaluation method can be expanded. It currently only matches words exactly.

Example of Suffix->Prefix table structre:
```
	k = {
		m = {
			"monk",
		},
		l = {
			"link"
		}
	}
	e = {
		f = {
			"face",
			"frostbite",
		}
	}
```
In this example, the word 'free' would return with 'face' and 'frostbite'.

## 
## Benchmark

Model name: Intel(R) Core(TM) i3-1005G1 CPU @ 1.20GHz
CPU max MHz: 3400.0000
CPU min MHz: 400.0000

> small_log.txt (1.6M)
```
lines: 100000
words: 351864
curse: 2
clock: 1.055601
---------------
lines: 100000
words: 351864
curse: 2
clock: 1.058072
```
> large_logfile.txt (52M)
```
lines: 3000000
words: 11096248
curse: 87
clock: 35.671395
----------------
lines: 3000000
words: 11096248
curse: 87
clock: 35.798562
```