-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

local function collect_ngrams(spaceless_message, n, blacklist_ngrams)
  local selected_blacklist_ngrams

  for c = 1, #spaceless_message - n do
    local ngram = spaceless_message:sub(c, c + n)
    local ngram_candidates = blacklist_ngrams[ngram]

    if ngram_candidates then
      selected_blacklist_ngrams = selected_blacklist_ngrams or {}
      for _, entry in ipairs(ngram_candidates) do
        selected_blacklist_ngrams[entry.word] = {
          spaced_pattern = entry.spaced_pattern,
        }
      end
    end
  end

  return selected_blacklist_ngrams
end

    -- find potential candidates for pattern matching
local function cross_validate_ngrams(sanitized_message, blacklist)
  local spaceless_message = sanitized_message:gsub("%s+", "")
  local n = #spaceless_message

  local selected_blacklist_bigrams = collect_ngrams(spaceless_message, 1, blacklist.bigrams)
  local selected_blacklist_trigrams = collect_ngrams(spaceless_message, 2, blacklist.trigrams)

  if not selected_blacklist_bigrams or not selected_blacklist_trigrams then
    return nil
  end

  -- bigram table will always contain more entries than trigrams
  local candidate_pool = {}
  for word, entry in pairs(selected_blacklist_bigrams) do
    if selected_blacklist_trigrams[word] then
      candidate_pool[word] = entry
    end
  end

  if not next(candidate_pool) then candidate_pool = nil end

  return candidate_pool
end


local function triage_candidates(candidate_pool, sanitized_message, whitelist)
  local candidates

  for blacklisted_word, pattern in pairs(candidate_pool) do
    local partial_pattern = pattern.spaced_pattern

    for partial_match in sanitized_message:gmatch(partial_pattern) do
      for partial_match_word in partial_match:gmatch("%S+") do
        if not whitelist[partial_match_word] then
          if not candidates then
            candidates = {}
          end

          table.insert(candidates, {
            string_matched = partial_match,
            blacklisted_word = blacklisted_word,
          })

          break
        end
      end
    end
  end
  return candidates
end


local function ngram_triage(blacklist, whitelist)
  return function(sanitized_message)
    local candidate_pool = cross_validate_ngrams(sanitized_message, blacklist)
    if not candidate_pool then
      return nil, false
    end

    local selected_candidates = triage_candidates(candidate_pool, sanitized_message, whitelist)
    if selected_candidates then
      return selected_candidates, true
    end

    return nil, false
  end
end

return ngram_triage
