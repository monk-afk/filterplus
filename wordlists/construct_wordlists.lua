-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT
local function construct_blacklist(blacklist_array, pattern_words)
  local blacklist = {
    words = {},
    unspaced_patterns = {},
    bigrams = {},
    trigrams = {},
  }
  table.sort(blacklist_array)

  for _, word in ipairs(blacklist_array) do
    if not blacklist.words[word] then
      local chars = {}
      word:gsub(".", function(c) table.insert(chars, c) end)

      local unspaced_pattern
      if pattern_words[word] then
        unspaced_pattern = "%f[%g](%a-" .. table.concat(chars, "+") .. "+%a-)%f[%G]"
      end

      local entry = {
        word = word,
        unspaced_pattern = unspaced_pattern,
        spaced_pattern = "%f[%g](%a-" .. table.concat(chars, "+%s?") .. "+%a-)%f[%G]",
      }
      blacklist.words[word] = entry
      if unspaced_pattern then
        table.insert(blacklist.unspaced_patterns, entry)
      end

      -- ngram indexes containing patterns and corresponding vulgarities
      for c = 1, #word - 1 do
        local bigram = word:sub(c, c + 1)
        blacklist.bigrams[bigram] = blacklist.bigrams[bigram] or {}
        table.insert(blacklist.bigrams[bigram], entry)

        local trigram = word:sub(c, c + 2)
        if #trigram == 3 then
          blacklist.trigrams[trigram] = blacklist.trigrams[trigram] or {}
          table.insert(blacklist.trigrams[trigram], entry)
        end
      end
    end
  end
  return blacklist
end

-- for counting the frequency of ngrams
local function count_grams(word_list)
  local frequencies = {}
  for _, word in ipairs(word_list) do
    for pos = 1, #word - 1 do
      local gram = word:sub(pos, pos + 1)
      local freq = frequencies[gram] or 0
      frequencies[gram] = freq + 1
    end
  end
  return frequencies
end

-- construct whitelist + blacklist
local function construct_lists(wordlist_files, normalize, sanitize)
  local whitelist_array = dofile(wordlist_files.whitelist)
  local blacklist_array = dofile(wordlist_files.blacklist)
  local blacklist_patterns = dofile(wordlist_files.blacklist_patterns)
  local blacklist_muted = dofile(wordlist_files.blacklist_mutations)
  local mutation_exempt = dofile(wordlist_files.mutation_exceptions)
  local whitelist = {}

  for _, w in ipairs(whitelist_array) do
    local normalized = normalize(w)
    local sanitized = sanitize(normalized)

    whitelist[normalized] = true
    if sanitized and sanitized ~= "" then
      whitelist[sanitized] = true
    end
  end

  for _, w in ipairs(blacklist_muted) do
    table.insert(blacklist_array, w)
  end

  local pattern_words = {}
  for _, w in ipairs(blacklist_patterns) do
    pattern_words[normalize(w)] = true
  end

  local filtered_blacklist = {}
  for _, w in ipairs(blacklist_array) do
    w = normalize(w)
    if not whitelist[w] and not mutation_exempt[w] then
      table.insert(filtered_blacklist, w)
    end
  end

  local blacklist = construct_blacklist(filtered_blacklist, pattern_words)
  local blacklist_grams = count_grams(filtered_blacklist)
  local whitelist_grams = count_grams(whitelist_array)

  return blacklist, whitelist, blacklist_grams, whitelist_grams
end


return function(wordlist_files, normalize, sanitize)
  return construct_lists(wordlist_files, normalize, sanitize)
end
