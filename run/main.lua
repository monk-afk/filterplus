-- this is the main loop, to become the core.on_chat_message callback
local function on_chat_message(clip)
  local initial_learn_rate = clip.param_learn_rate

  local is_censored = dofile(clip.util_blacklist)(clip)
  local sanitize = dofile(clip.util_sanitizer) -- (clip)
  local update_embedding = dofile(clip.math_sigmoid)

  local get_cosine_similarities = dofile(clip.math_cosine)
  local get_vector, tensor_matrix, staging_words = dofile(clip.util_get_tensor)(clip)
  local get_mad, ema_mad_closure = dofile(clip.math_mad)
  local bias_trend = dofile(clip.math_bias_avg)

  local counter = dofile(clip.util_counter)()
  local high_frequency = dofile(clip.lib_connectives)

  local function get_embeddings(line)
    local embeddings = {}
    local weights = {}

    for word in line:gmatch("%a+") do
      if not high_frequency[word] then
        local vector = get_vector(word, tensor_matrix, staging_words)
        for n = 1, #vector do
          weights[#weights+1] = vector[n]
        end
        embeddings[#embeddings+1] = {word, vector}
      end
    end

    return embeddings, weights
  end


  io.write("Ready!\n"); io.stdout:flush()

  --[[ DEBUG ]] local color = dofile(clip.util_colorize) -- colors are nice
  --[[ DEBUG ]] local debug_output = {} -- debugging string
  --[[ DEBUG ]] local function evaluate_mad(msg_mad, mad_tsh, label, line)
  --[[ DEBUG ]]   return msg_mad > mad_tsh
  --[[ DEBUG ]]       and string.format(
  --[[ DEBUG ]]               "%s\t%s\t%s",
  --[[ DEBUG ]]               color("red", string.format("Thd: %.8f", mad_tsh)),
  --[[ DEBUG ]]               color("red", string.format("%s: %.8f", label, msg_mad)),
  --[[ DEBUG ]]               line
  --[[ DEBUG ]]           )
  --[[ DEBUG ]]       or string.format(
  --[[ DEBUG ]]               "%s\t%s\t%s",
  --[[ DEBUG ]]               label,
  --[[ DEBUG ]]               color("green", string.format("Thd: %.8f", mad_tsh)),
  --[[ DEBUG ]]               color("green", string.format("%s: %.8f", label, msg_mad)),
  --[[ DEBUG ]]               line
  --[[ DEBUG ]]           )
  --[[ DEBUG ]] end


  local update_ema_mad = ema_mad_closure()

  while true do  -- this is the main loop, to be replaced by core.on_chat_message()
    if not dofile(clip.run_signal) then break end -- so we can save the modified embeddings

    -- local line = io.input():read()
    local line = io.read():gsub("(.*issued command:%s/%a+%s[%a]+)", ""):gsub(".*issued command: ", "") -- stream debug.txt

    line = sanitize(line) -- heavy sanitize, leaving only letters

    if line and #line > 1 then
      local embeddings, weights = get_embeddings(line)

      if #embeddings > 0 then
        -- the first step is to calculate the mean absolute deviation of the embedded tensors
        local message_mad, mad_threshold = update_ema_mad(weights) -- move the bar
        local is_positive = nil -- live update the embedding's vector

        --[[ DEBUG ]] debug_output[1] = evaluate_mad(message_mad, mad_threshold, "MAD", line)

        if message_mad and message_mad >= mad_threshold then
          for _, embed in ipairs(embeddings) do
            local word,vector = embed[1], embed[2]
            local cosine_similarities = get_cosine_similarities(word, tensor_matrix, staging_words)
            local bias_direction = bias_trend(cosine_similarities[0])
            -- projection of the word cluster along the axis of vulgarity
            --[[ DEBUG ]] table.insert(debug_output,
            --[[ DEBUG ]]     evaluate_mad(bias_direction, mad_threshold, "Bias", word))

            if bias_direction > 0.3 then
              is_positive = true
              line = string.gsub(line, word, ("*"):rep(#word))
            end

            --[[ DEBUG ]] -- for n = 1, #cosine_similarities do
            --[[ DEBUG ]] -- local debug_similarities = string.format("%12s \t %.5f \t %.5f",
            --[[ DEBUG ]] --     cosine_similarities[n].word,
            --[[ DEBUG ]] --     cosine_similarities[n].similarity,
            --[[ DEBUG ]] --     bias_trend(cosine_similarities[n].vector
            --[[ DEBUG ]] --   ))
            --[[ DEBUG ]] --   table.insert(debug_output, debug_similarities)
            --[[ DEBUG ]] -- end
          end
        end

        if is_positive ~= nil then  -- only update embeddings if flagged by MAD
          local learn_rate = initial_learn_rate
          if is_positive then
            learn_rate = learn_rate * 1.25
          else
            learn_rate = learn_rate * 0.75
          end

          update_embedding(tensor_matrix, staging_words, embeddings, learn_rate, is_positive)
        end

        --[[ DEBUG ]] io.write(line, "\n", table.concat(debug_output, "\n"), "\n") ; io.stdout:flush()
        --[[ DEBUG ]] debug_output = {}
      end
    end

    if counter() >= 14500 then -- every 14500 (approx 24hr) messages we clear the staging words
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