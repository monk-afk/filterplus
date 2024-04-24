FilterPlus
----------
Chat filter and censor, mute command, player tags, and mention highlight.

Copyright (c) 2023 monk

Details
-------
- Indexed Lua patterns from blacklist. Matches words in blacklist including 
- Whitelist 
- Censored words with asterisk(*).
- Removes URL links.
- Chat tag supprt, includes ranks, exp, and faction support.
- Name mention highlight green text.
- Lowers caps in messages with over 16 characters.
- API will return true with the word censored by asterisk.

Chat commands
-------------
- Mute/Unmute player(s) by associated IP (requires `mute` priv)
  - Default is 2 minutes, two hour max
```md
/mute <playername> [<minutes>]
/unmute <playername>
```
- Manage mod_storage filter lists (requires `blacklist` priv)
```md
/filter <blacklist>|<whitelist>|<delete>|<search> <string>
```

Message Tags
------------
Message tag default format is: `<PlayerName>`.

Supported tags from mods if available: Ranks, Factions, Exp.

The minetest.conf setting must be true, and pass required values.

- `filterplus_ranks`: `{Rank}` requires a string and ColorString
- `filterplus_factions`: `[Faction]` requires a string and ColorString 
- `filterplus_exp`: `(Exp)` requires integer or string

Tag order is: `{Rank}[Faction](Exp)<PlayerName> message`

Additional Info
---------------
> Adding words with UTF-8 characters are saved to mod_storage as UTF reference codes (\u00f). This will cause many false-positives.

> If `tex` is a blacklisted word, all instances containing `tex` are filtered, such as `text`, `context`, `contextual`, etc. This means adding these branch words is redundant, root words should be sufficient.

> Filter lists are sorted by numerical index, not alphabetically. This allows for word priority when whitelist checking, for example, if `luck` and `luk` are blacklisted, saying `lucky` will catch the former first.

##
Current Version **`0.1.4`**