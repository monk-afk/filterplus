return function(module_files)
  -- logging
  local logger = module_files.logger

  -- word lists
  local blacklist, whitelist, b_grams, w_grams = dofile(module_files.construct_wordlists)(module_files)

  -- utilities
  local frequency_bias = dofile(module_files.frequency_bias)(b_grams, w_grams)
  local sanitize, reduce_repeating = dofile(module_files.sanitizer)
  local root_sum_squared = dofile(module_files.root_sum_squared)
  local edit_distance = dofile(module_files.edit_distance)

  -- filtering utils
  local triage_candidates = dofile(module_files.triage_closure)(whitelist)
  local get_candidates = dofile(module_files.get_candidates)

  local function edit_confidence(word, dist)
    if dist == 0 then return 1 end
    return 1 - (dist / #word)   -- proportion of matching structure
  end

  local function freq_confidence(freq_bias)
    return 1 / (1 + math.exp(-freq_bias))  -- sigmoid
  end

  local censor_threshold = 0.369

  return function(raw_message)
    raw_message = reduce_repeating(raw_message)

    local sanitized_message = sanitize(raw_message) -- strip everything except letters n spaces

    if not sanitized_message then return raw_message end -- nothing left after sanitize, emojis mostly

    -- collect candidates from character-level bigrams captured via rolling frame
    local candidate_pool, num_candidates = get_candidates(sanitized_message, blacklist)

    -- triage the candidates by pattern matching and validation
    if candidate_pool then

      -- get a table of the potential curses or nil
      local selected_candidates = triage_candidates(candidate_pool, sanitized_message)

      -- evaluate confidence of the triaged selections
      if selected_candidates then
        -- square of roots, not average (rms)
        local rss = root_sum_squared()

        for i, candidate in ipairs(selected_candidates) do
          local word, match = candidate.blacklisted_word, candidate.string_matched
          local dist = edit_distance(match, word) -- measure the edit distance

          local match_bias = frequency_bias(match) -- captured word's bigram frequency
          local curse_bias = frequency_bias(word) -- also blacklisted word frequency

          local edit_conf = edit_confidence(match, dist) -- confidence is lev_dist / characters
          local freq_conf = freq_confidence(match_bias) -- sigmoid confidence curve

          local freq_diff = math.abs(match_bias - curse_bias) -- absolute difference between what we captured and what is listed
          local structural_similarity = 1 - (freq_diff / (curse_bias + 1))

          local conf = edit_conf * freq_conf * structural_similarity -- final answer

          if conf > 0 then  -- negative confidence scores contribute to a higher positive RSS
            rss(conf) -- add it to the sum
          end

          selected_candidates[i].confidence = conf
        end

        table.sort(selected_candidates, function(a, b) return a.confidence > b.confidence end)

        local rss_confidence = rss() -- close the sum for squaring
        local is_censored = rss_confidence > censor_threshold

        logger(("[FilterPlus] %s RSS: %.6f CEN: %s RAW: %s"):format(
          selected_candidates[1].string_matched, rss_confidence, tostring(is_censored), raw_message
        ))

        if is_censored then
          for _, candidate in ipairs(selected_candidates) do
            local cursed = candidate.string_matched
            sanitized_message = sanitized_message:gsub(cursed, ("*"):rep(#cursed))
          end

          return sanitized_message
        end
      end
    end
    return raw_message
  end
end
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
