-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT
local function filterplusplus(path, logger)
  if not path:match("[/\\]$") then path = path .. "/" end

  local filtering = path .. "filtering/"
  local wordlists = path .. "wordlists/"
  local utilities = path .. "utilities/"

  local wordlist_files = {
    blacklist = wordlists .. "blacklist.lua",
    whitelist = wordlists .. "whitelist.lua",
    blacklist_patterns = wordlists .. "blacklist_patterns.lua",
    blacklist_mutations = wordlists .. "blacklist_mutations.lua",
    mutation_exceptions = wordlists .. "mutation_exceptions.lua",
  }

  local normalize = dofile(utilities .. "normalizer.lua")
  local sanitize = dofile(utilities .. "sanitizer.lua")

  local blacklist, whitelist, blacklist_grams, whitelist_grams =
    dofile(wordlists .. "construct_wordlists.lua")(wordlist_files, normalize, sanitize)

  local pattern_matching = dofile(filtering .. "pattern_matching.lua")(blacklist, whitelist)
  local ngram_triage     = dofile(filtering .. "ngram_triage.lua")(blacklist, whitelist)
  local confidence_score = dofile(filtering .. "confidence_score.lua")(
      dofile(utilities .. "frequency_bias.lua")(blacklist_grams, whitelist_grams),
      dofile(utilities .. "edit_distance.lua")
    )

  return dofile(filtering .. "filter_main.lua")(
      pattern_matching,
      ngram_triage,
      confidence_score,
      sanitize,
      normalize,
      logger or function() end
    )
end

return filterplusplus
