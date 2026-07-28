return function(b_grams, w_grams)
  -- Symmetric smoothing for both corpora.
  local alpha = 0.75
  local ln2 = 0.6931471805599453

  -- Corpus totals and shared gram vocabulary size are used to normalize
  -- gram counts into comparable probabilities.
  local b_total = 0
  local w_total = 0
  local vocab = {}
  local vocab_size = 0

  for gram, count in pairs(b_grams) do
    b_total = b_total + count
    if not vocab[gram] then
      vocab[gram] = true
      vocab_size = vocab_size + 1
    end
  end

  for gram, count in pairs(w_grams) do
    w_total = w_total + count
    if not vocab[gram] then
      vocab[gram] = true
      vocab_size = vocab_size + 1
    end
  end

  -- Additive smoothing denominators.
  local b_denom = b_total + (alpha * vocab_size)
  local w_denom = w_total + (alpha * vocab_size)

  -- Caches save repeated work during candidate scoring.
  local gram_cache = {}
  local word_cache = {}

  local function softplus(x)
    -- numerically stable approximation for large x
    if x > 40 then
      return x
    end
    return math.log(1 + math.exp(x))
  end

  local function gram_log_odds(gram)
    local cached = gram_cache[gram]
    if cached ~= nil then
      return cached
    end

    local b = (b_grams[gram] or 0) + alpha
    local w = (w_grams[gram] or 0) + alpha

    -- log P(gram|blacklist) - log P(gram|whitelist)
    -- positive  => more blacklist-like
    -- negative  => more whitelist-like
    local odds = math.log(b / b_denom) - math.log(w / w_denom)
    gram_cache[gram] = odds
    return odds
  end

  return function(word)
    local cached = word_cache[word]
    if cached ~= nil then
      return cached
    end

    local word_len = #word

    if word_len <= 1 then
      word_cache[word] = 0
      return 0
    end

    local sigma = 0
    local total_weight = 0

    for pos = 1, word_len - 1 do
      local gram = word:sub(pos, pos + 1)
      local shifted_pos = (word_len - pos + 1) / word_len -- prefix adds more weight
      local weight = shifted_pos

      sigma = sigma + (gram_log_odds(gram) * weight)
      total_weight = total_weight + weight
    end

    if total_weight == 0 then
      word_cache[word] = 0
      return 0
    end

    local mean_log_odds = sigma / total_weight

    -- Convert mean log-odds to a compressed non-negative bias score.
    -- neutral (0 odds) maps to 0, stronger blacklist evidence increases smoothly.
    local frequency_bias = softplus(mean_log_odds) - ln2
    if frequency_bias < 0 then
      frequency_bias = 0
    end

    word_cache[word] = frequency_bias
    return frequency_bias
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
