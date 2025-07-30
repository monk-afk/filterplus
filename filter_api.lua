  --==[[ FilterPlus 0.3.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
  -- 💩⚡ based on ngram scoring
local frequencies
local new_mad
local new_rms

local function get_score(word)
  local mad = new_mad() -- open a new closure
  local rms = new_rms()
  local word_len = #word

  -- [[ DEBUG ]] core.log("action", "[nG] " .. word)

  for n = 1, 3 do -- for gram sizes of 2, 3 and 4
    local sigma_black = 0
    local sigma_white = 0

    for pos = 1, word_len - n do
      local gram = word:sub(pos, pos + n)
      local shifted_pos = (word_len - pos + 1) / word_len -- prefix adds more weight
      local weight = shifted_pos * #gram  -- gram position * length of gram

      local b = frequencies["blacklist"][gram] or 0
      sigma_black = sigma_black + (b * weight)

      local w = frequencies["whitelist"][gram] or 0.1
      sigma_white = sigma_white + (w * weight)

      -- [[ DEBUG ]] core.log("action", string.format(
      -- [[ DEBUG ]] "[nG] %s:\t WL: Freq: %s, Sigma: %s \t|\t BL: Freq: %s, Sigma: %s",
      -- [[ DEBUG ]] gram, w, sigma_white, b, sigma_black))
    end

    local frequency_bias = sigma_black / (sigma_white + 1)
    rms(frequency_bias) --  accumulated ngram score
    mad(frequency_bias)

    --[[ DEBUG ]] core.log("action", "[nG] Frequency Bias: " .. frequency_bias)
  end
  return mad(), rms()  -- nil triggers the closure return
end


local function is_listed_closure(word_lists)
  return function(list_type, word)
    return word_lists[list_type].index[word]
  end
end

local is_word_listed
local ema_mad
local ema_rms

local function filter_message(word)
  local letters = #word

  if letters > 1 then
    if is_word_listed("white", word) then
      return word -- skip whitelist matches

    elseif is_word_listed("black", word) then
      return ("*"):rep(letters) -- skip blacklist matches (includes 2 char words)

    elseif letters >= 3 then -- check anything over 2 letters
      local deviation, magnitude = get_score(word)
      local mad_threshold = ema_mad(deviation)
      local rms_threshold = ema_rms(magnitude)
      --[[ DEBUG ]] local logline = string.format(
      --[[ DEBUG ]]     "[FilterPlus] Word: %s | MAD: %.8f (t: %.8f) | RMS: %.8f (t: %.8f)",
      --[[ DEBUG ]]     word, deviation, mad_threshold, magnitude, rms_threshold
      --[[ DEBUG ]]   )
      --[[ DEBUG ]] core.log("action", logline)
      if magnitude > rms_threshold and deviation > mad_threshold then
        return ("*"):rep(letters)  -- censored if above both thresholds
      end
    end
  end
  return word
end


local function register_on_chat(modpath)
  local word_lists = dofile(modpath .. "constructors.lua")(modpath)

  frequencies = {
    ["whitelist"] = word_lists.white.freqs,
    ["blacklist"] = word_lists.black.freqs
  }

  local sanitize = dofile(modpath .. "sanitizer.lua")
  local clean = dofile(modpath .. "clean.lua")

  is_word_listed = is_listed_closure(word_lists)

  ema_mad = dofile(modpath .. "ema.lua")(0.4) -- a threshold for each evaluation metric
  ema_rms = dofile(modpath .. "ema.lua")(0.3)

  new_mad = dofile(modpath .. "mad.lua")
  new_rms = dofile(modpath .. "rms.lua")

  core.log("action", "[FilterPlus] Ready for input!")
  return function(original_message)
    if original_message and #original_message >= 2 then
      original_message = original_message:gsub("%s%s+", " ")

      local cleaned_message = clean(original_message) -- removes spammy text
      -- [[ DEBUG ]] core.log("action", "[FilterPlus] Scrubbed: " .. cleaned_message)
      local sanitized_message = sanitize(cleaned_message) -- if censored, message is sent with heavy sanitization
      -- [[ DEBUG ]] core.log("action", "[FilterPlus] Sanitized: " .. sanitized_message)

      if sanitized_message and sanitized_message ~= "" then
        local censored_message = sanitized_message:gsub("%a+", filter_message)
        local is_censored = (sanitized_message ~= censored_message)

        local outgoing_message = is_censored and censored_message
            or cleaned_message

        return outgoing_message, is_censored
      end

      return cleaned_message
    end

    return original_message
  end
end

return register_on_chat
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (Discord ID: 699370563235479624)                    --
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