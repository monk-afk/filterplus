-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

local function record_candidate(
    candidates, recorded_candidate_keys, whitelist, blacklist_entry, string_matched
  )
  if not string_matched or whitelist[string_matched] then
    return
  end

  local candidate_key = blacklist_entry.word .. "\0" .. string_matched

  if recorded_candidate_keys[candidate_key] then
    return
  end

  recorded_candidate_keys[candidate_key] = true
  candidates[#candidates + 1] = {
    blacklisted_word = blacklist_entry.word,
    string_matched = string_matched,
  }
end


return function(blacklist, whitelist)
  return function(sanitized_message)
    local candidates = {}
    local recorded_candidate_keys = {}

    for word in sanitized_message:gmatch("%S+") do
      local blacklist_entry = blacklist.words[word]

      if blacklist_entry then
        record_candidate(
          candidates, recorded_candidate_keys, whitelist, blacklist_entry, word
        )
      end
    end

    for _, blacklist_entry in ipairs(blacklist.unspaced_patterns) do
      local string_matched = sanitized_message:match(blacklist_entry.unspaced_pattern)

      record_candidate(
        candidates, recorded_candidate_keys, whitelist, blacklist_entry, string_matched
      )
    end

    if #candidates > 0 then
      return candidates, true
    end

    return nil, false
  end
end
