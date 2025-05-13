  --==[[ FilterPlus 0.2.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
  -- Used under license:
  -- !!!!!!!!!!!! REMEMBER THE GITHUB LINK
  -- Copyright 2014 Francisco Zamora-Martinez
  -- Adaptation of Peter Norvig python Spelling Corrector:
  -- http://norvig.com/spell-correct.html
  -- Open source code under MIT license: http://www.opensource.org/licenses/mit-license.php
  -- some cuss words are frequently mutated as evasion attempts
  -- not all words can be mutated automatically without raising false-positives, such as ass.
  -- this will also create a rediculous amount of additional words to check for
  -- we'll sparringly use this method only on select words
  -- there's probably a more effective way to use this, i'll figure it out eventually
local function mutate()
  local alphabet = {}
  for a in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do 
    alphabet[#alphabet+1] = a
  end

  local mutant_list = {"bitch", "fuck"}
  local mutations = {}

  for _,word in ipairs(mutant_list) do
    local partials = {}
    local letters = {}

    for i = 1, #word do
      letters[i] = word:sub(i,i)
      -- paires parts of the word: {"f","uck"}, {"fu","ck"}, {"fuc","k"}
      partials[i] = {word:sub(1,i), word:sub(i)}
    end

    -- sentinels
    partials[0] = {"", word}
    partials[#word+1] = {word, ""}

    -- deletions (fck, fuc, fuk)
    for i = 2, #word do
      table.insert(mutations, partials[i-1][1] .. partials[i+1][2])
    end

    -- transposes (fcuk, fukc)
    for i = 2, #word-1 do
      table.insert(mutations, partials[i-1][1] .. letters[i+1] .. letters[i] .. partials[i+2][2])
    end

    -- replacements (fack, fbck)
    for i = 2, #word do
      for j = 1, #alphabet do
        table.insert(mutations, partials[i-1][1] .. alphabet[j] .. partials[i+1][2])
      end
    end

    -- insertions (fauck, fbuck)
    for i = 1, #word do
      for j = 1, #alphabet do
        table.insert(mutations, partials[i][1] .. alphabet[j] .. partials[i+1][2])
      end
    end
  end
  return mutations
end

return mutate
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
