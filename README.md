## Filter Plus

Word Filtering and Censor Module with blacklist searching by trie.

Created by monk <sub>(Discord: `monk.moe`)</sub>

<sup>Copyright (c) 2023, Licensed under MIT</sup>

##
Blacklisted words are indexed by length->suffix->prefix->word.

The filter removes URLs, extra spaces, and joins gapped words (w o r d g a p).

Censored words are replaced with asterisk(*), except filtered URLs are removed entirely. Uncensored words return to the message unaltered.

Mentioning other players by name followed by a colon, `monk:`, will send the message to that player in green text. 

Example of Length->Suffix->Prefix->Word table structre:
```lua
[4] = { k = { f = {"fork", "funk"},
              t = {"tank"}
            },
        o = { p = {"pogo"} },
      },
[5] = {	h = { c = {"coach"} },},
```
##

Chat chatcommands:

- Mute player: 
```md
/mute <playername> [<minutes>] -- (10 minutes if empty)
```
Remove mute
```md
/unmute <playername>
```
Manage the Blacklist
```md
/blacklist <insert>|<remove> <word>
```
##
### Version **`dev_0.08`**
- [X] Add items to black list from in-game
- [X] Automatic update if on black/white list changes
- [ ] Add /filter_off command to disable filter for self
- [X] Reload blacklist command
- [X] caps limit
- [X] links
- [ ] exp tag
- [ ] ranks
- [ ] faction tag
- [X] player, server tag
- [ ] filtering callbacks (api)
- [X] highlight name mentions
- [X] mute/unmute player
- [X] Figure out how to join gapped words
- [X] Replace words and punctuation as-is if not censored
- [ ] Scrape old blacklists into new
- [ ] 
- [ ] 
