
-- joins words with s p a c e s -- needs work
local function join_spaced(og_str)
  local str = " " .. og_str .. " " -- pad string with spaces
  -- only capture from match "space (letter) space letter space letter letter? space"
  local spaced_out = str:match("%s(%a)%s%a%s%a%s")

  if spaced_out then
    local merged = spaced_out -- becomes (letter)
    local function m(s) merged = s end -- needs to stay outside of the loop, otherwise is overwritten inside loop

    while true do
      -- first loop is only captured match
      local mstr = str:gsub("(" .. merged .. ")%s((%a)%s)", function(a,s,b)
        m(a .. b) -- for each letter after (%1) concat (%1) and (%3) into scoped var 'merged'
        return a .. s -- return (%1) and (%2) [removes middle space]
      end)

      -- when modified string is the same as padded og string, we've merged everything possible
      if mstr ~= str then str = mstr else break end
    end
  end
  -- clip padded spaces if they still exist
  return str:match("%s?(.+)%s?")
end


local function clean_message(str)
  -- lowercase everything
  str = join_spaced(str:lower()) -- str:lower() is depended on by online_players
      :gsub("h*t*t*p*s*:*/*/*%S*%.?[%a%d_-]+%.%a%a%a?/*%S*", "")  -- strip hyperlinks
      :gsub("[%a%p%d]+@[%a%p%d]+%.%a%a%a?", "")  -- email
      :gsub("1?0?%s?%(?%d%d%d%d?%)?%s?%-?%d%d%d%d?%s?%-?%d%d%d%d", "")  -- phone numbers
      :gsub("[%a%p%d]+", function(word) return word:sub(1, 23) end)  -- cut words longer than 23 letters
      :gsub("[^\32-\126]", "") -- remove all non-standard ascii

  while true do  -- for excessive repeating characters
    local mstr = str:gsub("([%a%p%d][%a%p%d])(%1%1)", "%2")
    if mstr ~= str then str = mstr else break end
  end

  return str
end

return clean_message
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (https://github.com/monk-afk)                       --
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
