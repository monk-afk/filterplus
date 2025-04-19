local function blacklist_closure(clip)
  local blacklist = {}
  local frontier = {}
  local blacklist_strict = {}

  -- exhaustive compilation of all words to be matched 1:1
  for f, word in ipairs(dofile(clip.lib_strictlist)) do
    blacklist_strict[word] = true
  end

  -- loose pattern to capture context of flagged words
  for n, word in ipairs(dofile(clip.lib_blacklist)) do
    blacklist[word] = "(%a-" .. word:gsub(".", "%1+%%s?") .. "%a*i*n*g*e*d*r*s*)"
  end

  -- for isolating the blacklisted word in the flagged context
  for n, word in ipairs(dofile(clip.lib_blacklist)) do
    local f = "^(" .. word:sub( 1, 1) .. "+%s?"
    for c = 2, #word -1 do
      f = f .. word:sub(c, c) .. "+" .. "%s?"
    end
    frontier[word] = f .. word:sub(-1, -1) .. "+%a-i*n*g*e*d*r*s*)$"
  end

  local whitelist_check = dofile(clip.util_whitelist)(clip)

  return function(str)
    local is_positive = false
    return coroutine.wrap(function()
      for blacklisted_word, pattern in pairs(blacklist) do
        for flagged_context in str:gmatch(pattern) do
          local isolated_flag = flagged_context:gsub(frontier[blacklisted_word], "%1")
          for word in string.gmatch(isolated_flag, "%a+") do
            if blacklist_strict[word]
                or blacklist_strict[flagged_context:gsub("%s", "")]
                or not whitelist_check(word) then
              coroutine.yield(word)
            end
          end
        end
      end
    end)
  end
end

return blacklist_closure
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