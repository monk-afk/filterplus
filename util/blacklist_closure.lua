-- callback closure for checking the blacklist
local function blacklist_closure(clip)
local blacklist = {}

  -- construct patterns from blacklist file
  for _, word in ipairs(dofile(clip.lib_blacklist)) do
    blacklist[#blacklist + 1] = "(%a-" .. word:gsub(".", "%%s?%1+") .. "[%a%s]-)%f[%A]"
  end

  return function(str)
    return coroutine.wrap(function()
        for i, pattern in ipairs(blacklist) do
          for flagged_context in str:gmatch(pattern) do
            for flagged_word in flagged_context:gsub("(%f[%a])(%a)%s", "%1%2"):gmatch("%a+") do
              coroutine.yield(flagged_word)  -- return words to be cosine evaluated
            end
          end
        end
      end
    )
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