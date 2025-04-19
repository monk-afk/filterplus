-- for ansi coloring debug output
local c = {
  ["clear"]  = "\27[2J" ,
  ["blink"]  = "\27[5m" ,
  ["black"]  = "\27[30m",
  ["red"]    = "\27[31m",
  ["green"]  = "\27[32m",
  ["yellow"] = "\27[33m",
  ["blue"]   = "\27[34m",
  ["mauve"]  = "\27[35m",
  ["cyan"]   = "\27[36m",
  ["white"]  = "\27[37m",
  ["italic"] = "\27[3m" ,
  ["invert"] = "\27[7m" ,
  ["strike"] = "\27[9m" ,
  ["under"]  = "\27[4m" ,
  ["over"]   = "\27[53m",
  ["unset"]  = "\27[0m",
}

local string_format = string.format

local function color(clr, s)
  return string_format("%s%s%s", c[clr], s, c.unset)
end

return color
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