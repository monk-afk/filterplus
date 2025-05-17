-- train.lua
-- pre-process, create and train word embeddings
-- run tokenizer first to tokenize lines
local function run_trainer(clip)
  local ost = os.time()
  local vector_layers = clip.param_vector_layers
  local initial_learn_rate = clip.param_learn_rate

  local blacklist_check = dofile(clip.util_blacklist)(clip)
  local add_gradient    = dofile(clip.math_sigmoid)
  local save_table      = dofile(clip.util_save_table)
  -- local high_frequency  = dofile(clip.lib_connectives)  -- on the fence about this
  -- experimenting with rolling frames. also add to tokenizer?
  -- local frame_words  = dofile(clip.util_frame_words)

  local counter = dofile(clip.util_counter)()
  local total_lines = dofile(clip.util_line_count)(clip.lib_tokens)

  print("Begin training.", "Epochs:", clip.param_epochs,
      "Learn Rate:", clip.param_learn_rate, "Vector Layers:", clip.param_vector_layers)

  local string_match  = string.match
  local string_format = string.format
  local string_gmatch = string.gmatch

  local staging_words = {}  -- only make permanent embedding after many utterances
  local check_for_word, tensor_matrix, staging_words = dofile(clip.util_get_tensor)(clip)

  for epoch = 1, clip.param_epochs do
    counter(true)

    for eval in io.lines(clip.lib_tokens) do
      local learn_rate = initial_learn_rate
      local is_positive, line = string_match(eval, "(%a+):([%a%s]+)")
      is_positive = is_positive == "true"

      --[[ this is meant to impact curses more strongly than non-curses, because
            non curses appear more frequently than curses ]]
      if is_positive then  -- positive is curse, add more weight
        learn_rate = learn_rate * 1.25
      else
        learn_rate = learn_rate * 0.75  -- add less weight to good words
      end

      local embeddings = {}

      -- for _,window in ipairs(frame_words(line, embeddings)) do
        -- for _,word in ipairs(window) do
      for word in string_gmatch(line, "%a+") do
        -- if not high_frequency[word] then -- it's difficult to say whether omitting high frequency words is helping
        local word_tensor = check_for_word(word, tensor_matrix, staging_words)  -- get embeddings
        embeddings[#embeddings+1] = {word, word_tensor}
        -- end
      end

      add_gradient(tensor_matrix, staging_words, embeddings, learn_rate, is_positive) -- calculate new embedded values

      for n = 1, #embeddings do -- update embedded vectors
        if embeddings[n] then
          local embedded_word = embeddings[n][1]
          local updated_vector = embeddings[n][2]

          if tensor_matrix[embedded_word] then
            for k = 1, #updated_vector do
              tensor_matrix[embedded_word][k] = updated_vector[k]
            end

          -- table structure is slightly different for staging words
          elseif staging_words[embedded_word] then
            for k = 1, #updated_vector do
              staging_words[embedded_word].vector[k] = updated_vector[k]
            end
          end
        end
      end

      local count = counter()
      -- higher wipe threshold makes for more staging words to be added to embeddings file
      local wipe_stage_after_count = 14200
      if count % wipe_stage_after_count == 0 then
        local c = dofile(clip.util_counter)()
        for _ in pairs(staging_words) do
          c()
        end

        io.write(string_format("Ep %d | %.02f%% | %d | Stage wipe: %d\n",
                epoch, (count / total_lines) * 100,
                os.time() - ost, c() - 1
              )); io.stdout:flush()
        --[[ not clearing the staging table causes embeddings file to be heavy
             it's not clear if clearing staging_words helps overall
        ]]
        -- staging_words = {}
      end

      if not dofile(clip.run_signal) then break end
    end

    save_table(tensor_matrix, clip.lib_embeddings) -- saves the embeddings after every epoch
  end
end

return run_trainer
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2025 monk (Discord ID: 699370563235479624)                         --
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