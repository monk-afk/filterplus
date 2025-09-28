  --==[[ FilterPlus 0.3.1 ]]==--
  --==[[ monk © 2023-2025 ]]==--
  -- 💩⚡ based on ngram scoring
local ema_mad
local ema_rms

-- local frequencies
local new_mad
local new_rms

local function filter_message(frame, frequencies, is_word_listed)
  -- print(table.concat(frame, " "))
  local mad = new_mad() -- open a new closure
  local rms = new_rms()

  for i, word in ipairs(frame) do
    if is_word_listed("black", word) then
      return frame
    end

    local word_len = #word
    if word_len > 1 then
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
          -- [[ DEBUG ]] io.write(string.format("%4s\t W:Fq:%4d, Sg: %4d \t|\t B:Fq: %4d, Sg: %4d\n", gram, math.floor(w), math.floor(sigma_white), b, math.floor(sigma_black)))
        end
        local frequency_bias = sigma_black / (sigma_white + 1)
        rms(frequency_bias) --  accumulated ngram score
        mad(frequency_bias)
          -- [[ DEBUG ]] print("Frequency Bias:", frequency_bias)
      end
    end
  end
  -- end
  local deviation, magnitude = mad(), rms()
  local mad_threshold = ema_mad(deviation)
  local rms_threshold = ema_rms(magnitude)
  -- [[ DEBUG ]] local logline = string.format("Frame: %s |\t MAD: %.3f (t: %.3f) |\t RMS: %.3f (t: %.3f)",
  -- [[ DEBUG ]]     table.concat(frame, " "), deviation, mad_threshold, magnitude, rms_threshold)
  -- [[ DEBUG ]] print("DEBUG", logline)
  if magnitude > rms_threshold and deviation > mad_threshold then
    -- frame[i] = ("*"):rep(word_len)  -- censored if above both thresholds
    -- print("\27[31m Would be censored\27[0m")
  -- else
    -- print("\27[32m All good!\27[0m")
    return frame
  end
end


local function clear_table(t) -- saves GC from mapping new memory addresses
  for i,_ in pairs(t) do t[i] = nil end
end


-- construct frames of 3 words per frame, supplement short messages with neutral words
local function frame_closure(modpath)
  local neutral_words = dofile(modpath .. "neutral_words.lua")

  local frames = {}
  local words = {}
  local frame_size = 3

  return function(message)
    if message and message ~= "" then
      clear_table(words)

      message:gsub("%a+", function(word) table.insert(words, word) end)

      local word_count = #words

      if word_count == 0 then
        return words -- empty table

      elseif word_count < frame_size + 4 then
        for n = word_count, frame_size + 2 do
          local x1 = math.random(1, #neutral_words)
          local x2 = math.random(1, #neutral_words)
          table.insert(words, 1, neutral_words[x1])
          table.insert(words, neutral_words[x2])
        end
      end

      clear_table(frames)

      word_count = #words

      for i = 1, (word_count - math.min(word_count, frame_size) + 1) do
        local frame = {table.unpack(words, i, i + math.min(word_count, frame_size) - 1)}
        table.insert(frames, frame)
      end

      return frames
    end
  end
end

local function is_listed_closure(word_lists)
  return function(list_type, word)
    return word_lists[list_type].index[word]
  end
end


local function register_on_chat(modpath)
  local word_lists = dofile(modpath .. "constructors.lua")(modpath)
  local is_word_listed = is_listed_closure(word_lists)
  local framer = frame_closure(modpath)

  local frequencies = {
    ["whitelist"] = word_lists.white.freqs,
    ["blacklist"] = word_lists.black.freqs
  }

  local sanitize = dofile(modpath .. "sanitizer.lua")
  local clean = dofile(modpath .. "clean.lua")

  ema_mad = dofile(modpath .. "ema.lua")(0.3) -- a threshold for each evaluation metric
  ema_rms = dofile(modpath .. "ema.lua")(0.3)

  new_mad = dofile(modpath .. "mad.lua")
  new_rms = dofile(modpath .. "rms.lua")

  local flagged_words = {}

  print("action", "[FilterPlus] Ready for input!")

  return function(original_message)
    if original_message and #original_message >= 2 then
      original_message = original_message:gsub("%s%s+", " ")

      local cleaned_message = clean(original_message) -- removes spammy text
      local sanitized_message = sanitize(cleaned_message) -- if censored, message is sent with heavy sanitization

      if sanitized_message and sanitized_message ~= "" then
        local sanitized_frames = framer(sanitized_message)

        clear_table(flagged_words)

        for _, frame in ipairs(sanitized_frames) do
          local flagged_frames = filter_message(frame, frequencies, is_word_listed)
          if flagged_frames then
            for _, word in ipairs(flagged_frames) do
              -- count them?
              local f = flagged_words[word]
              flagged_words[word] = f and f + 1 or 1
            end
          end
        end

        local outgoing_message
        local is_censored = false

        if next(flagged_words) then
          outgoing_message = sanitized_message
          for word, count in pairs(flagged_words) do
            if count >= 3 and not is_word_listed("white", word) then
              outgoing_message = outgoing_message:gsub(word, ("*"):rep(#word))
              is_censored = true
            end
          end
        end

        return outgoing_message and outgoing_message or cleaned_message, is_censored
      end

      return cleaned_message
    end

    return original_message
  end
end


local function filter_cli()
  local modpath = io.popen("pwd"):read() .. "/"
  local filter = register_on_chat(modpath)

  while true do
    local user_input = io.input():read()
    if user_input == [[/reload]] then
      filter = register_on_chat(modpath)
    else
      local filtered_message, is_censored = filter(user_input)
      local output = string.format(
        "Original Text: %s\nFiltered Text: %s\nis_censored: %s\n",
        user_input, filtered_message, is_censored)
      io.write(output)
    end
  end
end


return filter_cli()
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (Discord: monk.moe)                                 --
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