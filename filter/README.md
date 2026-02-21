# Chat Filter Module

## Overview

This drop-in module implements a multi-stage, scoring-based profanity filter for chat streams. It is self-contained, with no dependencies on external APIs, and can run as a standalone Lua library in any environment that supports Lua 5.1 or later.

## Installation

Copy the filter_module folder into your project and require it in your code:

```lua
    -- absolute path to the parent mod without trailing slash
  local modpath = core.get_modpath(core.get_current_modname())

  local api_module_path = modpath .. "/filter_api/init.lua"

  local filter = dofile(api_module_path)(modpath)
```

## Usage

Filter a raw message:

```lua
  local raw_message = "example badword"

  local sanitized_message = filter(raw_message)

  print(sanitized_message)  -- censored or not
```

## CLI

The filter is a standalone module, which can be run from command prompt.

```bash
# enter the filter's root
$ cd filter

# run with lua using -l argument
$ lua -l init
Lua 5.4.7  Copyright (C) 1994-2024 Lua.org, PUC-Rio
> init("./")("test")
test

```

## Filtering Method Summary

It boils down to this:

  1. Strip a message down to letters and spaces.

  2. Select blacklist candidates via rolling bigram activation.
    - > "example" -> [ex], [xa], [am], [mp], [pl], [le]

  3. Triage the selected candidates by pattern matching and self-verification.

  4. Score each surving candidate with three overlapping lenses:
    • edit_confidence: structural similarity via Levenshtein
    • freq_confidence: sigmoid of bigram bias
    • structural_similarity: bias difference between captured string and canonical blacklist shape

  5. Squash all candidate scores through the root-sum-squared accumulator.

  6. If the RSS exceeds the EMA threshold, censor *all matches* by replacing them in the sanitized message. In this case, the sanitized message is returned along with a boolean true. Otherwise, the
  original message is returned.

## Wordlists

The whitelist should contain words which will override any candidate analysis from the filtering process, even if that word exists in the blacklist. Words within the whitelist are indexed with true values during startup.

The blacklist is created from an array list of words provided by file `blacklist.lua`, as well as generating words from `blacklist_mutations.lua`. This file contains an adaptation of Peter Norvig's Spelling Corrector, Which has been modified heavily leaving only the mutation methods provided by the original author.

Patterns from the blacklist array words are pre-compiled and indexed by non-positional bigram:

```lua
["fu"] = {
  {pattern = "pattern", word = "fuk"},
  {pattern = "pattern", word = "fuck"},
  {pattern = "pattern", word = "fucks"},
  {pattern = "pattern", word = "fucker"},
  {pattern = "pattern", word = "fucking"},
},
["ck"] = {
  {pattern = "pattern", word = "fuck"},
  {pattern = "pattern", word = "jackass"},
}

```

Once both word lists have been populated, we then count bigrams from each word to become our *bigram frequency* indices.

___

### Known Issues

No filtering system is flawless, including this one. Rigorous field testing will give opportunity to document observed evasion methods and filtering misses.

___

## License

```
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2026 monk (https://github.com/monk-afk)                            --
--                                                                                --
-- Permission is hereby granted, free of charge, to any person obtaining a copy   --
-- of this software and associated documentation files (the "Software"), to deal  --
-- in the Software without restriction, including without limitation the rights   --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      --
-- copies of the Software, and to permit persons to whom the Software is          --
-- furnished to do so, subject to the following conditions:                       --
--                                                                                --
-- The above copyright notice and this permission notice shall be included in all --
-- copies or substantial portions of the Software.                                --
--                                                                                --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  --
-- SOFTWARE.                                                                      --
------------------------------------------------------------------------------------
```
