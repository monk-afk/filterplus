-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

local function confidence_score(frequency_bias, edit_distance)
  local function edit_confidence(word, dist)
    if dist == 0 then return 1 end
    return 1 - (dist / #word)   -- proportion of matching structure
  end

  local function freq_confidence(freq_bias)
    return 1 / (1 + math.exp(-freq_bias))  -- sigmoid
  end

  local function root_sum_squared()
    local sum = 0  -- accumulate weights before squaring the root
    return function(val)
      if not val then
        return math.sqrt(sum)
      end
      sum = sum + (val * val)
    end
  end

  local confidence_threshold = 0.369

  return function(candidates)
    for _, candidate in ipairs(candidates or {}) do
      local match = candidate.string_matched
      local rss = root_sum_squared()
      local candidate_scores = {}

      for _, word in ipairs(candidate.blacklisted_words) do
        local dist = edit_distance(match, word) -- measure the edit distance

        local match_bias = frequency_bias(match) -- captured word's bigram frequency
        local curse_bias = frequency_bias(word) -- also blacklisted word frequency

        local edit_conf = edit_confidence(match, dist) -- confidence is lev_dist / characters
        local freq_conf = freq_confidence(match_bias) -- sigmoid confidence curve

        local freq_diff = math.abs(match_bias - curse_bias) -- absolute difference between what we captured and what is listed
        local structural_similarity = 1 - (freq_diff / (curse_bias + 1))

        local conf = edit_conf * freq_conf * structural_similarity -- confidence

        if conf > 0 then
          rss(conf)
        end

        candidate_scores[#candidate_scores + 1] = {
          blacklisted_word = word,
          confidence = conf,
        }
      end

      local total_candidates = #candidate_scores
      local confidence = total_candidates > 0 and rss() / math.sqrt(total_candidates) or 0

      candidate.candidate_scores = candidate_scores
      candidate.confidence = confidence
      candidate.confidence_judgement = confidence > confidence_threshold and "bad" or "amb"
    end

    return candidates
  end
end

return confidence_score
