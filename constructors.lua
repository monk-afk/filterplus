  --==[[ FilterPlus 0.3.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
-- to extract and quantify morphemes from a corpus
local function word_grammer()
  return function(word)
    return coroutine.wrap(function()
      for n = 1, 3 do -- do this for each gram size.
        for pos = 1, #word - n do
          local gram = word:sub(pos, pos + n)
          coroutine.yield(gram)
        end
      end
    end)
  end
end

-- for counting the frequency of ngrams
local function count_grams(contents, frequencies)
  local grammer = word_grammer()
  for _, word in ipairs(contents) do
    for gram in grammer(word) do
      local freq = frequencies[gram] or 0
      frequencies[gram] = freq + 1
    end
  end
  return frequencies
end


local function populate_tables(modpath)
  local word_lists = {
    white = {array = dofile(modpath .. "whitelist.lua"), index = {}},
    black = {array = dofile(modpath .. "blacklist.lua"), index = {}},
  }

  for _, word in ipairs(word_lists.white.array) do
    word_lists.white.index[word] = true
  end

  for _, word in ipairs(word_lists.black.array) do
    if not word_lists.white.index[word] then
      word_lists.black.index[word] = true
    end
  end

  -- populate ngram frequency tables
  for list_color, list_type in pairs(word_lists) do
    word_lists[list_color]["freqs"] = {}
    local array_list = word_lists[list_color].array
    local frequencies = word_lists[list_color].freqs
    word_lists[list_color].freqs = count_grams(array_list, frequencies)
  end

  return word_lists 
end
return populate_tables
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