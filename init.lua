local version_string = [[
  FilterPlus      | 0.4.0-dev
  MIT © 2025 monk | https://github.com/monk-afk/filterplus
]]

local util_dir   = "util/"   -- shared utilities
local lib_dir    = "lib/"    -- shared libraries (tables)
local run_dir    = "run/"    -- runtime launchers
local math_dir   = "math/"   -- mathematics
local corpus_dir = "corpus/" -- training data

local clip = dofile(util_dir .. "clip.lua") -- CLI args and shared objects
if clip.help or clip.h then
  return dofile(run_dir .. "help.lua")(version_string)
end

clip.param_epochs        = tonumber(clip.ep) or 10      -- repeating the training session
clip.param_learn_rate    = tonumber(clip.lr) or 0.00001 -- learn rate
clip.param_vector_layers = tonumber(clip.dim) or 5       -- embedded vector dimentions

clip.corpus_messages = corpus_dir .. "messages.txt" -- see readme for links to online corpuses

clip.run_signal    = run_dir .. "signal.lua"             -- graceful exit signal if return is false
clip.run_main      = run_dir .. "main.lua"               -- the main filter process
clip.run_tokenizer  = run_dir .. "tokenizer.lua"         -- pre-process (tokenize) the corpus data
clip.run_trainer   = run_dir .. "train.lua"              -- training function after tokenizing

clip.math_sigmoid   = math_dir .. "sigmoid_derivative.lua"       -- updates embedded vectors
clip.math_meansqrt  = math_dir .. "root_mean_squared.lua"        -- magnitute value or frequency
clip.math_cosine    = math_dir .. "cosine_similarity.lua"        -- similar direction of vectors
clip.math_mad       = math_dir .. "mean_absolute_deviation.lua"  -- magnitute value or frequency

clip.util_sanitizer   = util_dir .. "sanitizer.lua"        -- heavy sanitizing strings
clip.util_save_table  = util_dir .. "save_table.lua"       -- table saving
clip.util_get_tensor  = util_dir .. "get_tensor.lua"       -- fetch tensor from embeddings or staging
clip.util_line_count  = util_dir .. "line_count.lua"       -- count lines in file
clip.util_counter     = util_dir .. "counter_closure.lua"  -- closure for counting

clip.util_blacklist = util_dir .. "blacklist_closure.lua"  -- blacklist pattern construct
clip.util_whitelist = util_dir .. "whitelist_closure.lua"  -- it would be best to not need this

clip.lib_whitelist   = lib_dir .. "whitelist.lua"     -- list of non-vulgar words (negatives)
clip.lib_blacklist   = lib_dir .. "blacklist.lua"     -- list of vulgar words (positives)
clip.lib_embeddings  = lib_dir .. "embeddings.lua"    -- the embeddings table (will be created if non-existent)
clip.lib_tokens      = lib_dir .. "tokens.lua"        -- blacklist-whitelist evaluated messages
clip.lib_evalflags   = lib_dir .. "eval_flags.lua"    -- temporary for counting the curses flagged during tokenization

-- change to "return false" to terminate gracefully
if not dofile(clip.run_signal) then
  io.open(clip.run_signal, "w"):write("return true"):close()
end

-- checking command line options
if clip.eval then -- tokenize data
  dofile(clip.run_tokenizer)(clip)
end

if clip.train then  -- train the embeddings
  dofile(clip.run_trainer)(clip)

elseif clip.main then  -- run the message filter
  return dofile(clip.run_main)(clip)

elseif clip.search then  -- search and display the cosin similar words
  -- usage: `lua init.lua search=someword
  local tensor_matrix = dofile(clip.lib_embeddings)
  local target_word = clip.search
  local cos = dofile(clip.math_cosine)
  local mad,_ = dofile(clip.math_mad)

  local result = cos(target_word, tensor_matrix, {})

  io.write("Similar Word\tSimilarity\n")

  for n = 1, #result do
    io.write(string.format("%12s \t %.5f \n",
      result[n].word, result[n].similarity))
  end
end



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