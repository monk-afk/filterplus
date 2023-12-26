## Chat Filter -- for Minetest

Chat Message Filter and Censor Module, with Index-Key Associated Blacklist.

Created by monk <sub>(monk.moe @ [SquareOne](https://discord.gg/pE4Tu3cf23))</sub>

<sup>Copyright (c) 2023-2024, Licensed under MIT</sup>

##
Messages are filtered using blacklist associations via word length->suffix->prefix->word.

The filter removes URLs within strings, extra spaces, and joins gapped words. Numbers and symbols are ignored during blacklist check.

Example of Suffix->Prefix table structre:
```lua
	[3] = { o = { "one" } },
	[4] = { m = { "mono", "monk" },
			l = { "link" } },
	[6] = { s = { "square" } },
```
Words filtered are replaced with asterisk(*) before sending to public chat.

Reload the filter lists after adding new words manually to the table files, use the in-game command: `/reindex`

##
### Version **`dev_0.06`**
- [ ] Add items to black list from in-game
- [ ] Automatic update if on black/white list changes
- [ ] Add /filter_off command to disable filter for self
- [X] Reload blacklist command
- [X] caps limit
- [X] links
- [ ] exp tag
- [ ] ranks
- [ ] faction tag
- [ ] player, server tag
- [ ] filtering callbacks (api)
- [ ] highlight @name mentions
- [ ] mute player
- [X] Figure out how to join gapped words
- [X] Replace words and punctuation as-is if not censored
- [ ] Scrape old blacklists into new
- [ ] 
- [ ] 
