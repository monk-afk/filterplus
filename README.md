## FilterPlus
Tree indexed chat filter and censor, mute command, player tags, and mention highlight.

monk 

<sup>Copyright (c) 2023, MIT License</sup>

## Details
The blacklist is indexed by length->anchor(Z)->anchor(A)->word.

Removes URLs, trims extra spaces, and joins gapped words.

Censored words are replaced with asterisk(*).

Player tag format is: `{Rank}[Faction](Exp)<PlayerName>`.

Mentioning players by name sends green text.

If blacklist is not found in mod_storage, it is created from `blacklist.lua`.
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
##
**Planned Updates**
- [ ] Add /filter_off command to disable filter for self
- [ ] Scrape previous blacklists into new (multi-lingual)
- [ ] Additional evasion techniques
- [ ] Add mute-time check to /mute
- [ ] Export blacklist

Current Version **`0.011`**
