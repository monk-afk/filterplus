  -- Adaptation of Peter Norvig's python Spelling Corrector:
    -- http://norvig.com/spell-correct.html
  -- Original code by:
    -- https://github.com/pakozm/lua-spell-correct
    -- Copyright 2014 Francisco Zamora-Martinez

-- Instead of hand-curating hundreds of curse variants
-- this file automatically generates them based on key placements

local function mutate()
  local fat_finger_map = {
    a = {"q","w","s","z","x"},
    b = {"v","g","h","n"},
    c = {"x","d","f","v"},
    d = {"s","e","r","f","c","x"},
    e = {"w","s","d","r"},
    f = {"d","r","t","g","v","c"},
    g = {"f","t","y","h","b","v"},
    h = {"g","y","u","j","n","b"},
    i = {"u","j","k","o"},
    j = {"h","u","i","k","n","m"},
    k = {"j","i","o","l","m"},
    l = {"k","o","p"},
    m = {"n","j","k"},
    n = {"b","h","j","m"},
    o = {"i","k","l","p"},
    p = {"o","l"},
    q = {"w","a"},
    r = {"e","d","f","t"},
    s = {"a","w","e","d","x","z"},
    t = {"r","f","g","y"},
    u = {"y","h","j","i"},
    v = {"c","f","g","b"},
    w = {"q","a","s","e"},
    x = {"z","s","d","c","a"},
    y = {"t","g","h","u"},
    z = {"a","s","x"},
  }

  -- SEE FILE: mutation_exceptions.lua
  local blacklist = {
    "bitch",
    "dick",
    "fuck",
    "fucker",
    "fucking",
    "nigger",
    "shit",
    "puta",
    "sexy",
    "faggot",
    "asshole"
  }

  local mutations = {}

  for _,word in ipairs(blacklist) do
    local partials = {}
    local letters = {}
    local position_map = {}

    for i = 1, #word do
      letters[i] = word:sub(i,i)
      position_map[i] = fat_finger_map[letters[i]] or {}
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
      local mapped = position_map[i]
      for j = 1, #mapped do
        table.insert(mutations, partials[i-1][1] .. mapped[j] .. partials[i+1][2])
      end
    end

    -- insertions (fauck, fbuck)
    for i = 1, #word do
      local mapped = position_map[i]
      for j = 1, #mapped do
        table.insert(mutations, partials[i][1] .. mapped[j] .. partials[i+1][2])
      end
    end
  end

  return mutations
end

return mutate()
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
