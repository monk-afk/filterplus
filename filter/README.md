# Chat Filter Module

## Overview

This drop-in module implements a multi-stage, scoring-based profanity filter for chat streams. It is self-contained, with no dependencies on external APIs, and can run as a standalone Lua library in any environment that supports Lua 5.1 or later.

## Installation

Copy the filter_module folder into your project and require it in your code:

```lua
    -- absolute path to the parent mod without trailing slash
  local modpath = core.get_modpath(core.get_current_modname())

  -- to enable logging pass a log function
  local logger = function(...) core.log("info", ...) end

  local api_module_path = modpath .. "/filter_api/init.lua"

  local filter = dofile(api_module_path)(modpath, logger)
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

# with logging enabled
> init("./", print)("fuck")
[FilterPlus] fuck RSS: 0.879125 CEN: true RAW: fuck
****

> init("./", print)("scunthorpe manuscript")
[FilterPlus] manuscript RSS: 0.282843 CEN: false RAW: scunthorpe manuscript
scunthorpe manuscript

```

Alternatively, the included `init_cli.lua` can be invoked from command line; `lua init_cli.lua`

## Filtering Method Summary

It boils down to this:

  1. Reduce excessive repetition, then normalize the message to lowercase letters and spaces.

  2. Select blacklist candidates via rolling bigram activation.
    - > "example" -> [ex], [xa], [am], [mp], [pl], [le]

  3. Triage the selected candidates by pattern matching.

  4. Score each candidate with three overlapping lenses:
    • edit_confidence: structural similarity via Levenshtein
    • freq_confidence: sigmoid of bigram bias
    • structural_similarity: bias difference between captured string and canonical blacklist shape

  5. Squash all candidate scores through the root-sum-squared accumulator.

  6. If the RSS exceeds the censor threshold, *all candidate matches* are replaced in the sanitized message.

In the case of censoring, the sanitized message is returned with each selected match replaced by asterisks.  
Otherwise, the repeat-reduced message is returned unchanged.

## Wordlists

The whitelist should contain words which often trigger false-positive filtering, and will override candidate analysis in the filtering process.

The blacklist file `blacklist.lua` contains words from which patterns will be created.

`blacklist_mutations.lua` contains an adaptation of Peter Norvig's Spelling Corrector to generate word mutations based on key placements.

`mutation_exceptions.lua` is a list of words to not include in the mutations table.

Patterns from the blacklist array words are pre-compiled and indexed by non-positional bigram:

```lua
["fu"] = {
  {pattern = "pattern", word = "fuck"},
  {pattern = "pattern", word = "shitfu"},
},
["ck"] = {
  {pattern = "pattern", word = "fuck"},
  {pattern = "pattern", word = "jackass"},
}

```

# Utilities

`edit_distance.lua` uses a weighted Damerau-Levenshtein distance function tuned for profanity obfuscation; split/join spacing, adjacent-key typos and transpositions are penalized less.

The return value is a numeric "edit cost" between two strings, the candidate matched and the blacklisted word:
  - lower cost  = structurally more similar
  - higher cost = more different

Unlike classic Levenshtein (all edits cost 1), this version uses:
  - weighted insert/delete/substitute costs
  - explicit adjacent transposition support ("fu kc" style swaps)
  - keyboard-neighbor awareness via fat-finger mapping

`frequency_bias.lua` builds a cached scorer from the blacklist and whitelist bigram counts. It applies additive smoothing, calculates each bigram's normalized blacklist-versus-whitelist log-odds, and gives earlier bigrams slightly more weight. The weighted mean is compressed into a non-negative bias score: `0` means no net blacklist evidence, while larger values indicate a more blacklist-like structure.

`root_sum_squared.lua` returns a stateful accumulator. Passing a number adds its square to the running sum; calling it with no value returns the square root of that sum. The filtering path uses this to combine positive candidate confidence scores without averaging them.

`sanitizer.lua` exports two preprocessing functions. `reduce_repeating` collapses repeated whitespace and excessive repeated character sequences. `sanitize` lowercases the message, removes unsupported punctuation and symbols, normalizes whitespace, and joins letters separated to evade matching. The sanitized form is used for candidate matching and becomes the returned text only when censoring occurs.

`exponent_average.lua` **deprecated** calculates the average RSS using an EMA function resistant to deviation and a softening of the curve during normal chat.

## Filtering Path

`get_candidates.lua` removes spaces from the sanitized message and scans it with a rolling two-character window. Each bigram activates entries in the precompiled blacklist index. Activated entries are deduplicated by blacklisted word and returned as a candidate pool with their partial-match patterns.

`triage_closure.lua` builds a triage function around the whitelist. For each pooled blacklist candidate, it applies the candidate's partial pattern to the sanitized message, extracts alphabetic matches, rejects exact whitelist entries, and returns records linking each captured string to its canonical blacklisted word and full partial capture.

`filtering_main.lua` constructs the wordlists and helper closures once, then returns the message filter. For each message it:

  1. Reduces repetition and sanitizes the text.
  2. Selects candidates by bigram and triages them by partial pattern and whitelist.
  3. Scores each selected candidate from weighted edit similarity, frequency confidence, and the frequency-bias difference from its canonical blacklist word.
  4. Adds positive confidence scores to the root-sum-squared accumulator and compares the result with the fixed censor threshold.
  5. If the threshold is exceeded, replaces every selected match in the sanitized message with same-length asterisks; otherwise, returns the repeat-reduced message.

When a logger is supplied, the filter also reports the highest-confidence match, combined RSS score, censor decision, and processed raw message.

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
