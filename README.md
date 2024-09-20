FilterPlus
----------

Primarily a chat filter, also censors content via API.

Copyright (c) 2023 monk

[![ContentDB](https://content.minetest.net/packages/monk/filterplus/shields/downloads/)](https://content.minetest.net/packages/monk/filterplus/)

Details
-------

- Blacklisted words indexed by pattern.
- Robust Whitelist.
- Censors words with asterisk(*).
- Lowers casing in messages exceeding max_caps setting.
- Support for Chat rank/tags.
- Mention player by name sends green text messages.
- Filter list management and chat moderation commands.
- Removes URL links.
- API will return true with the word censored by asterisk.

Chat commands
-------------

### **Block**

> This command checks for `staff` priv and prevents staff ranked players from blocking and being blocked.

Stop incoming messages from a player, and outgoing messages from being seen by player. Also blocks private messages from blocked players. The block is enforced until the internally managed online players table purges the player who issued the block from the online players list, approx. 1 hour after they log out.

- Block/unblock

`/block <player_name>`

`/unblock <player_name>`

- List players in your block list

`/unblock <>` (empty argument)

- Clear your blocklist

`/unblock <*>`

### **Mute**

Disables a player from using public chat, does not mute private messaging. Applied to players by IP address, so any players currently online or alt accounts to join will be muted until the time expires. Can be used on offline players if they were online recently (approx 1 hour).

- Mute/Unmute player(s) by associated IP (requires `mute` priv)
  - Default is 2 minutes, two hour max

`/mute <playername> [<minutes>]`

`/unmute <playername>`


### **Filter List management**

- Manage mod_storage filter lists (requires `blacklist` priv)

`/filter <blacklist>|<whitelist>|<delete>|<search> <string>`

- Add word to whitelist, or blacklist (will automatically remove word from opposite list)

`/filter whitelist word`

`/filter blacklist word`

- Delete word from all filter lists (bug: it doesn't)

`/filter delete word`

- Search for word in either filter lists

`/filter search word`

- Save filters to mod_storage from memory after making changes to filters via command (blacklist, whitelist)

`/filter_save <whitelist>|<blacklist>`

- To restore the filters, override the filter lists mod_storage or Lua file:

`/filter_reload <mod_storage>|<file>`

### **Private Message**

Overrides the default `/msg` command to allow blocking private messages. Additionally, a "`to: <player>`" message shows in the sender's chat when a private message is sent.

Message Tags
------------
Player nametag in chat default format is: `<PlayerName>`.

Supported tags from mods if available: Ranks, Factions, Exp.

The minetest.conf setting must be true, and pass required values.

- `filterplus_ranks`: `{Rank}` requires a string and ColorString
- `filterplus_factions`: `[Faction]` requires a string and ColorString 
- `filterplus_exp`: `(Exp)` requires integer or string

Tag order is: `{Rank}[Faction](Exp)<PlayerName> message`


API
---
Not limited to chat messages. Strings from any mod can be checked against filter api:

`filterplus_api.check_word(string)`

This will return with the string, censored or not, with boolean:

`return "This **** is censored", true`

`return "This word is not censored", false`


Additional Info
---------------
- **UTF-16 or non-ASCII characters**
> Adding words by command containing UTF-8 characters are saved to mod_storage as UTF reference codes (\u00f). This will cause many false-positives. Workaround this by adding these words to the *list.lua files, then run `/filter_reload`


- **Pattern matches from blacklist are ordered**

> Filter lists are sorted by numerical index, not alphabetically. This allows for word priority when list checking, for example, if `luck` and `luk` are blacklisted, saying `lucky` will catch the former first.

> If `tex` is a blacklisted word, all instances containing `tex` are filtered, such as `text`, `context`, `contextual`, etc. This means blacklisting these branch words is redundant, root words should be sufficient.


##
Current Version **`0.1.5`**