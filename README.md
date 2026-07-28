# FilterPlus

FilterPlus is a chat filter written in Lua.  

It normalizes and sanitizes each message, gathers possible blacklist matches 
from two independent matchers, scores the resulting candidates, and classifies 
each capture by a two-of-three vote.

The primary interface is a single filter function. A removable command-line
adapter is included for reviewing messages and preparing classified corpora.

Requires LuaJIT or Lua 5.2 and later.

No external Lua modules or dependencies.

## Using the filter

Load `init.lua`, then construct a filter with the path to the FilterPlus
directory:

```lua
local create_filter = dofile("/path/to/filterplus/init.lua")
local filter = create_filter("/path/to/filterplus")

local filtered_message, bucket, candidates = filter("hello there")
```

The path may end in `/` or `\`; FilterPlus adds a separator when one is absent.

Callers interested only in the filtered text may ignore the additional return
values:

```lua
local filtered_message = filter(message)
```

### Return values

Every call returns:

```lua
filtered_message, bucket, candidates
```

- `filtered_message` is the original message for clean and ambiguous results.
  Dirty messages are returned in normalized, sanitized form with each capture
  receiving at least two votes replaced by asterisks.
- `bucket` is `"clean"`, `"ambig"`, or `"dirty"`.
- `candidates` is a table of diagnostic records grouped by matched string.

Candidate records include the matched string, supporting blacklist words,
matcher votes, confidence information, and the final vote count. These records
are useful for diagnostics and downstream review; filtering does not require a
caller to inspect them.

### Logging

An optional logger can be supplied when constructing the filter:

```lua
local function log_filter_result(message)
  io.stderr:write(message, "\n")
end

local filter = create_filter(
  "/path/to/filterplus",
  log_filter_result
)
```

The logger is called for each capture classified as dirty. FilterPlus otherwise
has no output or filesystem-write side effects.

## Classification

Consensus is calculated independently for each canonical sanitized capture:

1. Pattern matching casts one vote for exact words and selected unspaced
   patterns.
2. Ngram triage casts one vote after bigram/trigram cross-validation and
   spaced-pattern validation.
3. Confidence scoring casts one vote from edit-distance and frequency evidence
   across the blacklist words supporting that capture.

A capture is dirty when it receives at least two votes.

- `clean`: neither matcher produced a capture.
- `ambig`: one or more captures were found, but none received two votes.
- `dirty`: at least one capture received two votes.

Only dirty captures are censored. An ambiguous capture elsewhere in a dirty
message remains visible.

## Command-line corpus adapter

The adapter reads one message per line from standard input and writes classified
messages with candidate diagnostics to:

```text
bucketing/corpus/bucket_output/messages_clean.txt
bucketing/corpus/bucket_output/messages_ambig.txt
bucketing/corpus/bucket_output/messages_dirty.txt
```

Run it interactively:

```sh
luajit bucketing/filter_cli.lua
```

Or redirect a line-oriented corpus:

```sh
luajit bucketing/filter_cli.lua < messages.txt
```

The adapter resolves its paths from `filter_cli.lua`, so it may be launched from
another working directory.

Each run opens all three output files in write mode and replaces their existing
contents. Preserve any output you need before starting another run.

`bucketing/corpus/messages_link.sh` contains a download command for an external
Minecraft chat dataset used as an example corpus source. Downloaded structured
data must be converted to one message per line before being passed to the
adapter.

The adapter and buffer controller depend on FilterPlus. FilterPlus itself does
not depend on either component and can be packaged without `bucketing/`.

## Wordlists

Wordlist sources are under `wordlists/`:

- `blacklist.lua`: canonical blacklist entries.
- `whitelist.lua`: allowed words protected from matching.
- `blacklist_patterns.lua`: entries eligible for unspaced pattern matching.
- `blacklist_mutations.lua`: generated keyboard-error variants.
- `mutation_exceptions.lua`: generated variants excluded from the blacklist.

The runtime indexes and gram frequencies are rebuilt when the filter is
constructed.

## Project layout

```text
.
├── LICENSE
├── README.md
├── init.lua
├── filtering/
│   ├── confidence_score.lua
│   ├── filter_main.lua
│   ├── ngram_triage.lua
│   └── pattern_matching.lua
├── utilities/
│   ├── edit_distance.lua
│   ├── exponent_average.lua
│   ├── frequency_bias.lua
│   ├── normalizer.lua
│   └── sanitizer.lua
├── wordlists/
│   ├── blacklist.lua
│   ├── blacklist_mutations.lua
│   ├── blacklist_patterns.lua
│   ├── construct_wordlists.lua
│   ├── mutation_exceptions.lua
│   └── whitelist.lua
└── bucketing/
    ├── buffer_controller.lua
    ├── filter_cli.lua
    └── corpus/
        ├── messages_link.sh
        └── bucket_output/
            ├── messages_ambig.txt
            ├── messages_clean.txt
            └── messages_dirty.txt
```

[MIT](LICENSE) 

Copyright © 2026 monk (https://github.com/monk-afk)
