## Chat Filter

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023, Licensed under CC0</sup>

## 

Compares words in a string with words from a blacklist using a trie method. Much faster than matching words from a wordlist. This module only provides enough for a functional codebase.

The init.lua file will construct a trie table using the blacklist.lua. Each word is indexed by suffix -> prefix -> word.

Filter method: Remove extra whitespace and padding, remove non-alphabet characters, merge gapped words, then remove duplicate letters.  The string is then split into individual words.  Single-character words are ignored.  Cross-reference word suffix, then prefix, with the similarly indexed wordlist. Example: [m]on[k] suffix and prefix matches [m]in[k].  If an index pair is found, the word is checked against the returned keys. Currently only matches words exactly.

Example of Suffix->Prefix table structre:
```lua
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

## Benchmark

Intel(R) Core(TM) i3-1005G1 CPU @ 1.20GHz
> small_log.txt (1.6M)
```
lines: 100000
words: 251864
curse: 2
clock: 1.030832
---------------
lines: 100000
words: 251864
curse: 2
clock: 1.030534
```
> large_logfile.txt (52M)
```
lines: 3000000
words: 8096248
curse: 87
clock: 34.668115
----------------
lines: 3000000
words: 8096248
curse: 87
clock: 33.885449
```
