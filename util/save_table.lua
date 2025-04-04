-- save_table.lua
-- serializes table with opening return for dofile retrieval eg: return {["k"]="v"}
local function save_table(table_name, save_location)
  local function dump(o)
    local t = type(o)
    if t ~= "table" then
      if not tonumber(o) then
        return string.format("%q", o)
        else return tonumber(o)
      end
    end

    local output, cached = {}, {}
    for i, v in ipairs(o) do
      output[#output + 1] = dump(v)
      cached[i] = true
    end

    for k, v in pairs(o) do
      if not cached[k] then
        v = dump(v)
        if type(k) == "string" then
          k = "[" .. dump(k) .. "]"
        end
        output[#output + 1] = k .. "=" .. v
      end
    end
    return "{" .. table.concat(output, ",") .. "}"
  end
  io.open(save_location, "w"):write("return " .. dump(table_name)):close()
end
return save_table



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