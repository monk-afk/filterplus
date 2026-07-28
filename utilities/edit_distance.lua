-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

-- weighted Damerau-Levenshtein distance tuned for profanity obfuscation.
-- split/join spacing, adjacent-key typos and transpositions are penalized less.
--
-- This function returns a numeric "edit cost" between two strings:
--   - lower cost  = structurally more similar
--   - higher cost = more different
--
-- Unlike classic Levenshtein (all edits cost 1), this version uses:
--   - weighted insert/delete/substitute costs
--   - explicit adjacent transposition support ("fu kc" style swaps)
--   - keyboard-neighbor awareness via fat-finger mapping
--
-- The output remains a single scalar, so callers can keep using:
--   edit_confidence = 1 - (distance / #match)
local function measure_distance(source, target)
  -- Lengths are reused often, so keep them in locals.
  local len_s = #source
  local len_t = #target

  -- Neighbor-key map (QWERTY-ish) used to treat near-key substitutions
  -- as less severe than arbitrary substitutions.
  -- Example: "fuxk" vs "fuck" should score closer than a random swap.
  local fat_finger_map = {
    a = {"q","w","s","z","x"},
    b = {"v","g","h","n"},
    c = {"x","d","f","v"},
    d = {"s","e","r","f","c","x"},
    e = {"w","s","d","r"},
    f = {"d","r","t","g","v","c"},
    g = {"f","t","y","h","b","v"},
    h = {"g","y","u","j","n","b"},
    i = {"u","j","k","o"},
    j = {"h","u","i","k","n","m"},
    k = {"j","i","o","l","m"},
    l = {"k","o","p"},
    m = {"n","j","k"},
    n = {"b","h","j","m"},
    o = {"i","k","l","p"},
    p = {"o","l"},
    q = {"w","a"},
    r = {"e","d","f","t"},
    s = {"a","w","e","d","x","z"},
    t = {"r","f","g","y"},
    u = {"y","h","j","i"},
    v = {"c","f","g","b"},
    w = {"q","a","s","e"},
    x = {"z","s","d","c","a"},
    y = {"t","g","h","u"},
    z = {"a","s","x"},
  }

  -- Vowel substitutions are common in obfuscation ("shit" -> "shet", etc.),
  -- so they get an intermediate substitution cost.
  local vowels = {
    a = true,
    e = true,
    i = true,
    o = true,
    u = true,
    y = true  -- sometimes y
  }

  -- True if b is one of a's keyboard neighbors.
  -- Note this is directional in the map, so callers often check both ways.
  local function near_key(a, b)
    local neighbors = fat_finger_map[a]
    if not neighbors then return false end
    for i = 1, #neighbors do
      if neighbors[i] == b then
        return true
      end
    end
    return false
  end

  -- Insertion cost: adding spaces is cheap to catch split-word evasions
  -- like "fu ck".
  local function insertion_cost(char_t)
    if char_t == " " then return 0.15 end
    return 1.0
  end

  -- Deletion cost mirrors insertion cost.
  -- Removing spaces is cheap to catch join-word evasions.
  local function deletion_cost(char_s)
    if char_s == " " then return 0.15 end
    return 1.0
  end

  -- Substitution cost tiers:
  --   0.00 exact match
  --   0.20 space <-> letter (boundary manipulation)
  --   0.35 adjacent-key typo
  --   0.60 vowel-to-vowel
  --   1.00 any other substitution
  local function substitution_cost(char_s, char_t)
    if char_s == char_t then return 0.0 end
    if char_s == " " or char_t == " " then return 0.20 end
    if near_key(char_s, char_t) or near_key(char_t, char_s) then return 0.35 end
    if vowels[char_s] and vowels[char_t] then return 0.60 end
    return 1.0
  end

  -- Transposition cost for swapping adjacent chars:
  -- "fukc" vs "fuck" should be cheaper than two unrelated edits.
  local function transposition_cost(char_prev, char_curr)
    if near_key(char_prev, char_curr) or near_key(char_curr, char_prev) then return 0.35 end
    return 0.65
  end

  -- Base case: source is empty, so only insertions can build target.
  -- With weighted costs this is not just len_t.
  if len_s == 0 then
    local cost = 0
    for j = 1, len_t do
      cost = cost + insertion_cost(target:sub(j, j))
    end
    return cost
  end

  -- Base case: target is empty, so only deletions can reduce source.
  if len_t == 0 then
    local cost = 0
    for i = 1, len_s do
      cost = cost + deletion_cost(source:sub(i, i))
    end
    return cost
  end

  -- Dynamic programming state:
  -- previous_row[j]          = cost(source[1..i-1] -> target[1..j])
  -- current_row[j]           = cost(source[1..i]   -> target[1..j])
  -- previous_previous_row[j] = cost(source[1..i-2] -> target[1..j])
  --
  -- The extra previous_previous_row enables Damerau transposition checks.
  local previous_row = {[0] = 0}
  local previous_previous_row = nil

  -- Initialize row i=0 (empty source to target prefix),
  -- accumulating insertion costs across target chars.
  for j = 1, len_t do
    local char_t = target:sub(j, j)
    previous_row[j] = previous_row[j - 1] + insertion_cost(char_t)
  end

  -- Build each row i from 1..len_s.
  for i = 1, len_s do
    local current_row = {}
    local char_s = source:sub(i, i)

    -- First column j=0: converting source prefix to empty target
    -- requires deleting current source character.
    current_row[0] = previous_row[0] + deletion_cost(char_s)

    -- Fill row cells left-to-right.
    for j = 1, len_t do
      local char_t = target:sub(j, j)

      -- Standard weighted edit operations:
      --   delete source char
      --   insert target char
      --   substitute source->target char
      local delete_step = previous_row[j] + deletion_cost(char_s)
      local insert_step = current_row[j - 1] + insertion_cost(char_t)
      local replace_step = previous_row[j - 1] + substitution_cost(char_s, char_t)
      local best = math.min(delete_step, insert_step, replace_step)

      -- Damerau transposition:
      -- if current chars are crossed with previous chars, allow a swap step
      -- from cell [i-2, j-2] plus transposition cost.
      if i > 1 and j > 1 then
        local char_s_prev = source:sub(i - 1, i - 1)
        local char_t_prev = target:sub(j - 1, j - 1)

        -- Detect adjacent swap pattern:
        -- source: ...ab
        -- target: ...ba
        if char_s == char_t_prev and char_s_prev == char_t then
          local transposition_base = previous_previous_row and previous_previous_row[j - 2]
          if transposition_base then
            local transpose_step = transposition_base + transposition_cost(char_s_prev, char_s)

            -- Keep whichever operation path is cheapest.
            if transpose_step < best then
              best = transpose_step
            end
          end
        end
      end

      current_row[j] = best
    end

    -- Slide the DP window for the next source character.
    previous_previous_row = previous_row
    previous_row = current_row
  end

  -- Final cell holds full-string distance.
  return previous_row[len_t]
end

return measure_distance
