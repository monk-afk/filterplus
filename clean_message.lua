  --==[[ FilterPlus 0.2.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
-- joins words with s p a c e s
local function join_spaced(str)
  local str = " " .. str .. " "
  local spaced_out = str:match("%s(%a)%s%a%s%a%s")

  if spaced_out then
    local merged = spaced_out
    local function m(s) merged = s end

    while true do
      local mstr = str:gsub("(" .. merged .. ")%s((%a)%s)", function(a,s,b)
        m(a .. b)
        return a .. s
      end)
      if mstr ~= str then str = mstr else break end
    end
  end
  return str:match("%s?(.+)%s?")
end


local function clean_message(str)
  -- lowercase everything
  str = join_spaced(str:lower()) -- str:lower() is depended on by online_players
      :gsub("h*t*t*p*s*:*/*/*%S*%.?[%a%d_-]+%.%a%a%a?/*%S*", "")-- strip hyperlinks
      :gsub("[%a%p%d]+@[%a%p%d]+%.%a%a%a?", "")-- email
      :gsub("1?0?%s?%(?%d%d%d%d?%)?%s?%-?%d%d%d%d?%s?%-?%d%d%d%d", "")-- phone numbers
      :gsub("[%a%p%d]+", function(word) return word:sub(1, 23) end)-- cut words longer than 23 letters

  while true do -- for excessive repeating characters
    local mstr = str:gsub("([%a%p%d][%a%p%d])(%1%1)", "%2")
    if mstr ~= str then str = mstr else break end
  end

  return str
end

return clean_message
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