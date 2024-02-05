## FilterPlus
Trie indexed chat filter and censor, mute command, player tags, and mention highlight.

Copyright (c) 2023 monk <monk.squareone@gmail.com>

<sup>MIT License</sup>

## Details
The blacklist is indexed by length->anchor(Z)->anchor(A)->word.

Removes URLs, trims extra spaces, and joins gapped words.

Censored words are replaced with asterisk(*).

Player name message tagging with mods supported.

Mentioning players by name sends green text.

Lowers casing of messages over 16 characters.

If blacklist is not found in mod_storage, it is created from `blacklist.lua`.

Includes API for other mods to check words against blacklist.
## Chat commands
- Mute player (requires `mute` priv)
  - (10 minute min, two hour max)
```md
/mute <playername> [<minutes>]
```
- Remove mute (requires `mute` priv)
```md
/unmute <playername>
```
- Manage *mod_storage* blacklisted words (requires `blacklist` priv)
```md
/blacklist <insert>|<remove> <word>
```
## Message Tags
Message tag default format is: `<PlayerName>`.

Supported tags from mods if available: Ranks, Factions, Exp.

The minetest.conf setting must be true, and pass required values.

- `filterplus_ranks`
   - `{Rank}` requires a string and ColorString

- `filterplus_factions`
	- `[Faction]` requires a string and ColorString 

- `filterplus_exp`
	- `(Exp)` requires integer or string

Tag order is: `{Rank}[Faction](Exp)<PlayerName> message`
##

Current Version **`0.014`**