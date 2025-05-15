# FilterPlus

Filter content and censor profanity from public chat stream. Includes API for external mods, moderation tools, self-regulating utilities, and more.

Copyright © 2023-2025 monk (Discord ID: 699370563235479624)

[![ContentDB](https://content.luanti.org/packages/monk/filterplus/shields/downloads/)](https://content.luanti.org/packages/monk/filterplus/)

___

**Filter**

- Multi-pass filtering logic and validation.
- Censor profanity with asterisks(*).
- Clean messages before broadcasting to public.
  - Excessively long words
  - Excessive repeating characters
  - S p a c e d o u t w o r d s
  - Hyperlinks, emails, phone numbers
- Non-intrusive pre-filter string sanitizing.
  - If not censored, message is delivered as-is.
- Simple API callback for external mods.

**Plus**

- Message highlighting for players mentioned by name
- Proximity messaging with players within 100 nodes
- Stop unwanted messages by blocking them
- Moderate players arguing by blocking each other
- Moderate spammers by chat timeout
- Toggle public chat, and still accept direct messages
- Optional nametag flair from external mods

___

## Filter and Censor

Messages sent to public chat are filtered for profanity. Messages sent to other channels, such as private or group messaging, is left unfiltered.

There are a total of four filter lists constructed by the filter.

`blacklist_patterns.lua`: These words will be made into patterns. The list shouldn't be too long; more patterns increases processing time.

`blacklist_explicit.lua`: Explicit validation of words captured by pattern, and overrides the whitelist.

`blacklist_mutations.lua`: Repurposed spell-check which will mutate words hundreds of different ways to supplement the explicit blacklist. Add words with caution.

`whitelist.lua`: If the context words captured are not in the whitelist, they will be censored.

`filter_api.lua`: This is the main script containing closures to load the filters and process incoming messages.

`filter_cli.lua`: For porting or testing, a standalone version of the filter and API is provided.

`sanitizer.lua`: Heavy pre-filter sanitizer to facilitate the process. Messages will be sent as they were received if not censored. Before curse detection, the sanitizing function will:
  1. Replace symbols and non-standard ascii to a alphabetic equivalent
  2. Merge words with hyphens and apostrophes (you're -> your)
  3. Replace embedded number with alphabetic equivalent
  4. Replace any remaining non-letter symbols with a space
  5. Strip away excess spaces

`clean_message.lua`: A pre-sanitizing function intended to remove spammy formatting and content from a message before sanitizing. It can be used independent from the filter and will modify a string by:
  1. Lower-casing the entire string
  2. Join words separated with s p a c e s
  3. Strip hyperlinks, email address, phone numbers
  4. Clip words exceeding 23 characters
  5. Remove excess repeated charactersssssss

## Chat Commands

**`/block`**

- Stop public and private messages from being delivered.

- Persistent between logins until unblocked or server shutdown.

`/block` or `/unblock`: Without parameter will show your list of blocked players.
  - Players with `staff` privilege are not able to block or be blocked. Using the block command with player name will list the player's block list.

`/block player_name` or `/unblock player_name`: Add or remove another player from your blocked-players list.

`/forceblock player_name1 player_name2`: Add two players to each other's block list. Requires `mute` privilege.

**`/mute`**

- Timeout player from using public chat.

- Does not mute private messaging, faction messages, or proximity chat.

- Retroactively applied to alt-accounts using a 24-hour cache.

`/mute player_name minutes`: Defaults to 2 minutes if no parameter is provided, and 120 minutes maximum

`/unmute player_name`: To allow using public chat before timeout expires.

**`/chat`**

- Toggle seeing the public chat channel.

- Direct messages and group messages (eg, faction and proximity) are not affected.

`/chat`: No parameter is needed

**`/msg`**

- Overrides the default `/msg` command for compatibility with FilterPlus features

- Shows the sender their own message after it is sent.

`/msg message contents`: **not censored**

- Prefixed with `#/pm «PlayerName» ` and colored green for incoming, blue for outgoing messages.

**`/xm`**

- Proximity chat allows a distance limited conversation.

- Players within 100 nodes will see these messages in a cyan color, prefixed with `#/xm «PlayerName»`

`/xm message contents`: Usage is similar to a private message, **is censored**

> Note: to disable censoring /xm messages, modify the register_on_chatcommand from:

___

## Nametag Flair

Nametag default format is: `«PlayerName»`.

Supports tags from mods if available: Ranks, Factions, Exp.

Ensure the `minetest.conf` has the setting enabled, and that a callback exists in the global namespace:

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

A supporting mod should have a callback to provide variables to be used as the nametag flair.

There should only be two variables provided: text, and optional color.

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

The API will return the string, censored or not, with boolean `true` or `nil` to indicate whether the string was censored:

`return "Some text to be ********", true`

or

`return "Some text to be filtered", nil`

___

## CLI

The file named `filter_cli.lua` can be run as an independent tool, and can be imported to other applications if desired.

Simply run from terminal: `lua filter_cli.lua`

Receives user input and display the output of the filter as well as the API result.

___

Version `0.2.0`