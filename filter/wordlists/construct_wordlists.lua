return function(module_files)
  local function construct_blacklist(blacklist_array)
    local blacklist = {}
    table.sort(blacklist_array)

    for _, word in ipairs(blacklist_array) do
      local chars = {}
      word:gsub(".", function(c) table.insert(chars, c) end)

      local partial = "%f[%g](%a-" .. table.concat(chars, "+%s?") .. "+%a-)%f[%G]"

      local entry = {
        partial = partial,
        word = word
      }

      -- bigram index containing patterns and corresponding vulgarities
      --[[ ["fu"] = {
            {pattern = "pattern", word = "fuk"},
            {pattern = "pattern", word = "fuck"},
            {pattern = "pattern", word = "fucks"},
            {pattern = "pattern", word = "fucker"},
            {pattern = "pattern", word = "fucking"},
          } ]]

      for c = 1, #word - 1 do
        local gram = word:sub(c, c + 1)
        blacklist[gram] = blacklist[gram] or {}
        table.insert(blacklist[gram], entry)
      end
    end
    return blacklist
  end

  -- for counting the frequency of ngrams
  local function count_grams(word_list)
    local frequencies = {}
    for _, word in ipairs(word_list) do
      for pos = 1, #word - 1 do
        local gram = word:sub(pos, pos + 1)
        local freq = frequencies[gram] or 0
        frequencies[gram] = freq + 1
      end
    end
    return frequencies
  end

  -- construct whitelist + blacklist
  local function construct_lists()
    local whitelist_array = dofile(module_files.whitelist)
    local blacklist_array = dofile(module_files.blacklist)
    local blacklist_muted = dofile(module_files.blacklist_mutations)
    local mutation_exempt = dofile(module_files.mutation_exceptions)
    local normalize = dofile(module_files.normalizer)

    local whitelist = {}
    for _, w in ipairs(whitelist_array) do
      whitelist[w] = true
    end

    for _, w in ipairs(blacklist_muted) do
      table.insert(blacklist_array, w)
    end

    local filtered_blacklist = {}
    for _, w in ipairs(blacklist_array) do
      w = normalize(w)
      if not whitelist[w] and not mutation_exempt[w] then
        table.insert(filtered_blacklist, w)
      end
    end

    local blacklist = construct_blacklist(filtered_blacklist)

    local blacklist_grams = count_grams(filtered_blacklist)

    local whitelist_grams = count_grams(whitelist_array)

    return blacklist, whitelist, blacklist_grams, whitelist_grams
  end

  return construct_lists()
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
