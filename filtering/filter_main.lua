-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

local function evaluate_vote(has_vote, captured_candidates, vote_field, candidates, selected)
  if has_vote then
    for _, candidate in ipairs(captured_candidates) do
      local entry = selected[candidate.string_matched]

      if not entry then
        entry = {
          string_matched = candidate.string_matched,
          blacklisted_words = {},
          selected_blacklisted_words = {},
          pattern_vote = false,
          triage_vote = false,
          confidence_judgement = "abstain",
        }
        selected[candidate.string_matched] = entry
        candidates[#candidates + 1] = entry
      end

      if not entry.selected_blacklisted_words[candidate.blacklisted_word] then
        entry.selected_blacklisted_words[candidate.blacklisted_word] = true
        entry.blacklisted_words[#entry.blacklisted_words + 1] = candidate.blacklisted_word
      end

      entry[vote_field] = true
    end
  end
end


local function filter_main(
    pattern_matching, ngram_triage, confidence_score, sanitize, normalize, logger
  )
  return function(message)
    local sanitized_message = sanitize(normalize(message))
    if not sanitized_message or sanitized_message == "" or #message < 2 then
      return message, "clean", {}
    end

    local pattern_candidates, pattern_vote = pattern_matching(sanitized_message)
    local triage_candidates, triage_vote = ngram_triage(sanitized_message)
    local candidates = {}
    local selected = {}

    evaluate_vote(pattern_vote, pattern_candidates, "pattern_vote", candidates, selected)
    evaluate_vote(triage_vote, triage_candidates, "triage_vote", candidates, selected)

    for _, candidate in ipairs(candidates) do
      table.sort(candidate.blacklisted_words)
      candidate.selected_blacklisted_words = nil
    end

    table.sort(candidates, function(a, b)
      return a.string_matched < b.string_matched
    end)

    confidence_score(candidates)

    local bucket = "clean"
    for _, candidate in ipairs(candidates) do
      local votes = 0
      if candidate.pattern_vote then votes = votes + 1 end
      if candidate.triage_vote then votes = votes + 1 end
      if candidate.confidence_judgement == "bad" then votes = votes + 1 end

      candidate.votes = votes

      if votes >= 2 then
        bucket = "dirty"
        logger(("[FilterPlus] %s (%s) %d/3 [c: %.6f | t: %s | p: %s]"):format(
          table.concat(candidate.blacklisted_words, ", "),
          candidate.string_matched,
          candidate.votes,
          candidate.confidence,
          tostring(candidate.triage_vote),
          tostring(candidate.pattern_vote)
        ))
      elseif bucket ~= "dirty" then
        bucket = "ambig"
      end
    end

    if bucket == "dirty" then
      for _, candidate in ipairs(candidates) do
        if candidate.votes >= 2 then
          local cursed = candidate.string_matched
          sanitized_message = sanitized_message:gsub(cursed, ("*"):rep(#cursed))
        end
      end

      return sanitized_message, bucket, candidates
    end

    return message, bucket, candidates
  end
end

return filter_main
