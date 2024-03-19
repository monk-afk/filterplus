FilterPlus
----------
Chat message word filter censor and API. Includes, mute player, mod tag support, and mention highlight.

Copyright (c) 2023 monk

Filter
------
Match patterns constructed from blacklisted words, and censor the positive match if the contextual word or words are not whitelisted. For example,

- "`scunthorpe`" is whitelisted, and will not be censored.
- From "`scu nt horpe`", neither `scu` nor `nt` are whitelisted, and returns with "`*** ** horpe`".
- If `scu` is whitelisted, and `nt` is not, the string returns `scu ** horpe`

Plus
----
- API returns string and boolean, false if not censored.
- Expandable support for player "chat tags"
- Sends green message to players mentioned by name
- Lowers caps in messages over 16 characters
- Removes URL patterns
- Mute time applied to players' IP
- Manage filter lists in-game with chat commands

Chat commands
-------------
- Manage mod_storage filter lists (requires `blacklist` priv)
```md
/filter <blacklist>|<whitelist>|<delete>|<search> <string>
```

- Mute/Unmute player(s) (requires `mute` priv), by associated IP
  - Default is 10 minutes, two hour max
```md
/mute <playername> [<minutes>]
/unmute <playername>
```

Optional Depends for Message Tags
---------------------------------
Default no-tag format is: `<PlayerName>`.

Original release supports, if available: Ranks, Factions, Exp.

Add desired tags with optional color from external mods
```lua
    if mod_available then
        local tag_title, tag_color = mod.get_player_tag(msg_block[1])
        if tag_title then
            if not tag_color then
                tag_color = red
            end
            tags[#tags+1] = "{"..colorize(tag_color, tag_title).."}"
        end
    end
```


The minetest.conf settings:
- `filterplus_ranks`: `{Rank}` requires a string and ColorString
- `filterplus_factions`: `[Faction]` requires a string and ColorString 
- `filterplus_exp`: `(Exp)` requires integer or string

Tag order is: `{Rank}[Faction](Exp)<PlayerName> message`
##

File Versions
-------------
`init.lua` (0.1.2) For Minetest
`cli_bench.lua` (0.0.1) Portable CLI (Lua 5.3.6)
`blacklist.lua` (v6) 246 words Blacklisted
`whitelist.lua` (v1) 565258 words Whitelisted