-- The following code is used under license:
  -- https://github.com/pakozm/lua-spell-correct
  -- Copyright 2014 Francisco Zamora-Martinez
    -- Adaptation of Peter Norvig python Spelling Corrector:
    -- http://norvig.com/spell-correct.html
    -- Open source code under MIT license: http://www.opensource.org/licenses/mit-license.php


-- Some blacklisted words are especially prone to obfuscation by players.
-- Instead of hand-curating hundreds of variants this file automatically generates them
-- Use sparringly, each word added to this list will generate
  --  25 + (54 * (word:len() - 1)) additional blacklist words

local function mutate()
  local alphabet = {}
  for a in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    alphabet[#alphabet+1] = a
  end

  local mutant_list = {
    "bitch",
    "dick",
    "fuck",
    "fucking",
    "nigger",
    "shit",
    "puta",
    "sexy",
    "slut",
    "faggot",
    "asshole"
  }
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

return mutate()
