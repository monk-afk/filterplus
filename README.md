FilterPlus
----------
Chat filter and censor with API and features: Lowercase messages exceeding max_caps setting, Support for Chat rank/tags, Player-mention highlighting, Filter and chat moderation tools, etc.

Copyright (c) 2023 monk

Details
-------
- Blacklisted words indexed by pattern.
- Robust Whitelist compiled from real messages.
- Censors words with asterisk(*).
- Removes URL links.
- Chat rank/tagging supprt.
- Name mention highlights message with green text.
- Lowers caps in messages with over 16 characters.
- API will return true with the word censored by asterisk.

Chat commands
-------------
**Mute** players from using public chat, does not mute private messaging. Applied to players by IP address, so any players currently online or alt accounts to join will be muted until lifted. Can be used on offline players if they were online recently (approx 1 hour).

- Mute/Unmute player(s) by associated IP (requires `mute` priv)
  - Default is 2 minutes, two hour max
```md
/mute <playername> [<minutes>]
/unmute <playername>
```


**List management** only applies to the mod_storage file.

- Manage mod_storage filter lists (requires `blacklist` priv)
```md
/filter <blacklist>|<whitelist>|<delete>|<search> <string>
```

- Save filter lists to mod_storage. This is not automatic due to the size of the whitelist, saving to disk causes a moment of lag.
```md
/filter_save
```

- Reload the filter lists. Applies changes made to the filter files.
```md
/filter_reload
```

Message Tags
------------
Player nametag in chat default format is: `<PlayerName>`.

Supported tags from mods if available: Ranks, Factions, Exp.

The minetest.conf setting must be true, and pass required values.

- `filterplus_ranks`: `{Rank}` requires a string and ColorString
- `filterplus_factions`: `[Faction]` requires a string and ColorString 
- `filterplus_exp`: `(Exp)` requires integer or string

Tag order is: `{Rank}[Faction](Exp)<PlayerName> message`

Additional Info
---------------
- **UTF-16 or non-ASCII characters**
> Adding words by command containing UTF-8 characters are saved to mod_storage as UTF reference codes (\u00f). This will cause many false-positives.


- **Pattern matches from blacklist are ordered**

> Filter lists are sorted by numerical index, not alphabetically. This allows for word priority when list checking, for example, if `luck` and `luk` are blacklisted, saying `lucky` will catch the former first.

> If `tex` is a blacklisted word, all instances containing `tex` are filtered, such as `text`, `context`, `contextual`, etc. This means blacklisting these branch words is redundant, root words should be sufficient.


##
Current Version **`0.1.4`**