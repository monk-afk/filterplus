-- this is the main loop, which would act as the core.on_chat_message callback
local function on_chat_message(clip)
  local is_censored = dofile(clip.util_blacklist)(clip)
  local sanitize = dofile(clip.util_sanitizer)
  local update_embedding = dofile(clip.math_sigmoid)
  local get_cosine_similarities = dofile(clip.math_cosine)
  local get_vector, tensor_matrix, staging_words = dofile(clip.util_get_tensor)(clip)
  local get_mad, ema_mad_closure = dofile(clip.math_mad)
  local rms_closure = dofile(clip.math_meansqrt)
  local counter = dofile(clip.util_counter)()

  local function get_embeddings(line)
    local embeddings = {}
    local weights = {}
    for word in line:gmatch("%a+") do
      local vector = get_vector(word, tensor_matrix, staging_words)
      for n = 1, #vector do
        weights[#weights+1] = vector[n]
      end
      embeddings[#embeddings+1] = {word, vector}
    end

    return embeddings, weights
  end


  io.write("Ready!\n"); io.stdout:flush()

  --[[ DEBUG ]] local clr = {  -- ansii colors
  --[[ DEBUG ]]  set   = "\27[0m",  -- reset color
  --[[ DEBUG ]]  red   = "\27[31m",
  --[[ DEBUG ]]  green = "\27[32m",
  --[[ DEBUG ]]  yelo  = "\27[33m",
  --[[ DEBUG ]]  cyan  = "\27[96m",
  --[[ DEBUG ]] }
  --[[ DEBUG ]] local debug_output = {} -- debugging string
  --[[ DEBUG ]] local function evaluate_mad(msg_mad, mad_tsh, line)
  --[[ DEBUG ]] return msg_mad > mad_tsh and string.format("%s%.8f/%.8f%s\t%s", clr.red, msg_mad, mad_tsh, clr.set, line)
  --[[ DEBUG ]] or string.format("%s%.8f/%.8f%s\t%s", clr.green, msg_mad, mad_tsh, clr.set, line)
  --[[ DEBUG ]] end

  --[[ DEBUG ]] local dump = require("dump")
  local update_ema_mad = ema_mad_closure()

  while true do  -- this is the main loop, to be replaced by core.on_chat_message()
    if not dofile(clip.run_signal) then break end -- so we can save the modified embeddings

    local line = io.read():gsub("^(issued command:%s?/?%a*%s)([%S%s]+)", "%2")  -- reading from debug.txt

    line = sanitize(line) -- heavy sanitize, leaving only letters

    if line and #line > 1 then
      local embeddings, weights = get_embeddings(line)

      -- the first step is to calculate the mean absolute deviation of the embedded tensors
      local message_mad, mad_threshold = update_ema_mad(weights) -- move the bar
      local is_positive = false -- live update the embedding's vector

      --[[ DEBUG ]] debug_output[1] = evaluate_mad(message_mad, mad_threshold, line)
      if message_mad and message_mad >= mad_threshold then
        local get_rms = rms_closure()
        local censored_line = line

        for flagged_word in is_censored(line) do
          -- gather the top N cosin similar words
          -- Fatal: if word does not have cosine similar words, errors out with nil (see also line 22: cosine_similarity.lua)
          if flagged_word == "dickhead" then print(dump({embeddings, weights})) end -- dickhead causes the crash
          local cosine_similarities = get_cosine_similarities(flagged_word, tensor_matrix, staging_words)

          if not cosine_similarities then -- if there are none, use the embeddings of the flagged words instead
            _, cosine_similarities = get_embeddings(flagged_word, tensor_matrix)
          end

          -- accumulate mean of root-of mean absolute deviation
          get_rms(get_mad(cosine_similarities[0]))

          censored_line = string.gsub(censored_line, flagged_word, ("*"):rep(#flagged_word))
        end

        -- this sould be changed
        if censored_line ~= line then-- and get_rms() >= mad_threshold then
          local cosine_mad_rms = get_rms()

          if cosine_mad_rms >= mad_threshold then
            line = censored_line
            --[[ DEBUG ]] debug_output[2] = evaluate_mad(cosine_mad_rms, mad_threshold, line)
            is_positive = true
          end
        end
      end

      -- update embeddings in real-time
      -- need a way to trigger forced adjustment, some words get stuck in a false-neg/pos 
      update_embedding(tensor_matrix, staging_words, embeddings, clip.param_learn_rate, is_positive)
      --[[ DEBUG ]] io.write(table.concat(debug_output, "\n"), "\n") ; io.stdout:flush()
      --[[ DEBUG ]] debug_output[2] = nil
    end

    if counter() >= 500 then -- every 500 messages we clear the staging words
      counter(true) -- true to reset
      local c = dofile(clip.util_counter)() -- for debugging
      for _ in pairs(staging_words) do c() end -- debug
      io.write("Stage cleared: ", c() - 1, "\n");io.stdout:flush() -- debug
      staging_words = {}
    end
  end

  dofile(clip.util_save_table)(tensor_matrix, clip.lib_embeddings)
end

return on_chat_message



------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2025 monk                                                          --
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