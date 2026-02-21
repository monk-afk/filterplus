-- single-character edit distance; skit -> shit = 1
local function measure_distance(source, target)
  local len_s = #source
  local len_t = #target

  if len_s == 0 then return len_t end
  if len_t == 0 then return len_s end

  -- distance_row[j] = cost of converting source[1 .. i - 1] -> target[1 .. j]
  local previous_row = {}

  for j = 0, len_t do
    previous_row[j] = j
  end

  for i = 1, len_s do
    local current_row = {}
    current_row[0] = i
    local char_s = source:sub(i, i)

    for j = 1, len_t do
      local char_t = target:sub(j, j)
      local substitution_cost = (char_s == char_t) and 0 or 1

      current_row[j] = math.min(
        previous_row[j] + 1,  -- deletion
        current_row[j - 1] + 1,  -- insertion
        previous_row[j - 1] + substitution_cost  -- substitution
      )
    end
    previous_row = current_row
  end

  return previous_row[len_t]
end

return measure_distance
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
