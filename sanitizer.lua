local symbol_map = {
  ["£"] = "f",
  ["#"] = "h",
  ["$"] = "s",
  ["@"] = "a",
  ["+"] = "t",
}

local function sanitize(str)
  if str and str ~= "" then
    str = str:gsub("%A", function(c) return symbol_map[c] or c end)
      :gsub("[^%a%s]+", "")  -- remove remaining non-letters
      :gsub("%s+", " ")

    while true do -- remove anything more than two repeating letters, they make false positive
      local mstr = str:gsub("([%a])(%1%1)", "%2")
      if mstr ~= str then str = mstr else break end
    end
  end
  return str
end

return sanitize
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
