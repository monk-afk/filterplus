## Chat Filter

Filter blacklist words using index-key association table.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023, Licensed under CC0</sup>

##
Messages are filtered using blacklist words by associating suffix->prefix->word.  It removes extra whitespace, non-alphabet characters, duplicate letters, ~~and joins gapped words~~(nf) before the index search.

Example of Suffix->Prefix table structre:
```lua
k = { m = { "monk" },
      l = { "link" } },
e = { f = { "face", "frostbite" } }
```
Words filtered are replaced with asterisk(*) before sending to public chat.

Whitelist is checked first.

Reload the filter lists after adding new words manually to the table files, use the in-game command: `/reindex`

## 
**dev_0.04**
- [ ] Populate whitelist and verify function
- [ ] Add items to black/white list from in-game
- [ ] Automatic update if on black/white list changes
- [ ] Add colors and chat tags
- [ ] 
- [ ] To do
- [ ] To do