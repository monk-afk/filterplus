FilterPlus
----------
Chat filter and censor, mute command, player tags, and mention highlight.

Copyright (c) 2023 monk

Details
-------
- Chat messages filtered using pattern, able to filter word variants and mutations.
- Positive patterns are checked against whitelist before being censored.
- Censored words are replaced with asterisk(*).
- Removes URL links.
- Name tagging, includes ranks, exp, and faction support.
- Players mentioned sends green text.
- No caps for messages over 16 characters.

Includes API for other mods to check words against blacklist. Will return true with the word censored by asterisk.

Filtering pattern is: `(.*[fF]+[%s%p]-[uU]+[%s%p]-[cC]+[%s%p]-[kK]+[%s%p]-.*)`
In english: Match anything before the first letter, and spaces/punctuation between each letter, and everything after the last letter.

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
##
Current Version **`0.1.4`**