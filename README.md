# FilterPlus

Filter content and censor profanity from public chat stream. Includes API for external mods, moderation tools, self-regulating utilities, and more.

Copyright © 2023-2025 monk (Discord ID: 699370563235479624)

[![ContentDB](https://content.luanti.org/packages/monk/filterplus/shields/downloads/)](https://content.luanti.org/packages/monk/filterplus/)

___

**Filter**

- Novel filtering logic using n-gram scoring
- Censors profanity with asterisks(*)
- Cleans messages of spammy text
- Non-intrusive pre-filter heavy sanitizing
- Easy integration API callback for external mods

**Plus**

- Message highlighting for players mentioned by name
- Proximity chat command with players within 100 nodes
- Stop unwanted messages by blocking them
- Moderate players arguing by blocking each other
- Moderate spammers by chat timeout
- Toggle public chat via command without disabling private channels
- Support for nametag flair from external mods

___

## Filter and Censor

`filter_api.lua`: This is the main file to load the filter lists and process incoming messages.

Every string processed by the filter first undergoes a cleaning function to remove spammy formatting and content from a message:

`clean.lua`: 
  1. Lower-casing the entire string
  2. Join words separated with s p a c e s
  3. Strip hyperlinks, email address, phone numbers
  4. Clip words exceeding 23 characters
  5. Remove excess repeated charactersssssss

Then the message is sanitized before being evaluated. Messages will be sent as they were received if not censored.

`sanitizer.lua`
  1. Replace symbols and non-standard ascii to a alphabetic equivalent
  2. Merge words with hyphens and apostrophes (you're -> your)
  3. Replace embedded number with alphabetic equivalent
  4. Replace any remaining non-letter symbols with a space
  5. Strip away excess spaces

Messages are evaluated by using a frame scoring system based on `n-gram frequency` with `gram-positional weight`.

An 'n-gram' is basically a part of a word, the gram, and n is a number. If we say 2-gram (or bi-gram) that means every two letters in a word:

`word`: "wo", "or", "rd"

From our whitelist and blacklist words, we count and tally the grams of 2, 3, and 4, which will become our gram-frequencies.

This means for words like "fuck", the grams which occur in that word would be less frequent in the whitelist than the blacklist. For non-vulgar words, the opposite is true.

The filter then calculates the deviation and magnitude of a word's n-gram score, and compares them against a variable threshold.

This system allows profanity detection without relying on hard-coded pattern matching, and becomes resistant to mutation, character substitution, and partial obfuscation.

Update 0.3.1: Messages are evaluated using rolling frames of 3 words. If the MAD and RMS valuess exceed the threshold for a frame, and a word appearing across frames is flagged three times, it is considered vulgar.

For example, in the message "what a beautiful fucking day today" the frames are:

 - "what a beautiful" -> `not flagged`
 - "a beautiful fucking" -> `flagged`
 - "beautiful fucking day" -> `flagged`
 - "fucking day today" -> `flagged`

The flagged words are counted across the flagged frames, in the above example:

```
  a = 1
  beautiful = 2
  fucking = 3
  day = 2
  today = 1
```

Any word crossing the threshold would be censored.

## Chat Commands

**Blocking**

- Ignore all public and private messages from being delivered.

- Persistent between logins until unblocked or server shutdown.

`/block` or `/unblock`: Without parameter will show your list of blocked players.
  - Players with `staff` privilege are not able to block or be blocked. Using the block command with player name will list the player's block list.

`/block player_name` or `/unblock player_name`: Add or remove another player from your blocked-players list.

`/forceblock player_name1 player_name2`: Add two players to each other's block list. Requires `mute` privilege.

**Muting**

- Timeout player from using public chat.

- Does not mute private messaging, faction messages, or proximity chat.

- Retroactively applied to alt-accounts using a 24-hour cache.

`/mute player_name minutes`: Defaults to 2 minutes if no parameter is provided, and 120 minutes maximum

`/unmute player_name`: To allow using public chat before timeout expires.

**Toggle Chat**

`/chat`

- Toggle seeing the public chat channel.

- Direct messages and group messages (eg, faction and proximity) are not affected.

**Direct Message**

`/msg recipient_name message contents`

- Overrides the default `/msg` command for compatibility with FilterPlus features

- Shows the sender their own message after it is sent.

- Prefixed with `#/pm «PlayerName» ` and colored green for incoming, blue for outgoing messages.

**Proximity Chat**

- Proximity chat allows a distance limited conversation.

- Players within 100 nodes will see these messages in a cyan color, prefixed with `#/xm «PlayerName»`

`/xm message contents`: Usage is similar to a private message, **is censored**

> Note: to disable censoring /xm messages, modify the register_on_chatcommand from:

___

## Nametag Flair

Nametag default format is: `«PlayerName»`. Built-in support from mods if available: Ranks, Factions, Exp.

Ensure the `minetest.conf` has the setting enabled, and that the receiving mod exists in the global namespace:

```conf
# minetest.conf
filterplus_ranks = true
filterplus_factions = true
filterplus_exp = true
```

```lua
-- nametag_flair.lua
local factions_available = core.settings:get_bool("filterplus_factions") and
    core.global_exists("factions") == true
```

A supported mod should have a callback to provide only two variables: text, and optional color.

For example, the Factions mod would have a callback defined within itself. FilterPlus will attempt to call the external mod, expecting to receive a hex color and a text string:

```lua
-- ensure compatibility with your mod
local get_player_faction = factions_available and factions.is_player_in or function() return nil end

-- expects a string, and hexadecimal color
local faction_name, faction_color = get_player_faction(name)

-- the resulting flair will appear as colored string in brackets, eg: [Faction]
local faction_tag = faction_name and "[" .. colorize((faction_color or "#FFFFFF"), faction_name) .. "]" or ""
```

The default ordering of supported flair tags is: `{Rank}[Faction](Exp)«PlayerName» `

___

## Highlighted Mentions

Messages containing online player's name will be sent to the mentioned player as green text. If many players are mentioned, they will each receive green text.

___

## API

To filter and censor content from external mods, such as signs or login names, include a callback containing the string to be filtered in the external mod:

`filterplus.filter_check("Some text to be filtered")`

The API will return the string, censored or not, with booleans `true`, and `nil` or `false` to indicate whether the string was censored. A `false` return would indicate the string was filtered and not censored, while a `nil` return indicates the string was not filtered. All strings containing two or more characters will at the least be returned "cleaned".

`return "Some text to be ********", true`

or

`return "Some text to be filtered", nil`

___

## CLI

For testing or debugging, run the filter from command line:

`lua filter_cli.lua` or `cat some_file.txt | lua filter_cli.lua`

___

Version `0.3.1`

___

The other admins told me this was an impossible problem. Why didn't I listen?
