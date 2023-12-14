## Chat Filter -- for Minetest

Chat Message Filter and Censor Module, with Index-Key Associated Blacklist.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023-2024, Licensed under CC0</sup>

##
Messages are filtered using blacklist words by associating suffix->prefix->word.  It removes extra whitespace, non-alphabet characters, duplicate letters, ~~and joins gapped words~~(nf) before the index search.

Example of Suffix->Prefix table structre:
```lua
k = { m = { "monk" },
      l = { "link" } },
e = { f = { "face", "frostbite" } }
```
Words filtered are replaced with asterisk(*) before sending to public chat.

Reload the filter lists after adding new words manually to the table files, use the in-game command: `/reindex`

##
### Version **`dev_0.06`**
- [ ] Add items to black list from in-game
- [ ] Add /filter_off command to disable filter for self
- [ ] > ? Automatic update if on black/white list changes
- [X] Reload blacklist command
- [X] caps limit
- [X] links
- [ ] exp tag
- [ ] ranks
- [ ] faction tag + api support
- [ ] player, server tag
- [ ] > mention  -- is better way to do it?
- [ ] mute player
- [ ] Figure out how to join gapped words
- [ ] To do
- [ ] To do
- [ ] 
- [ ] 