-- rolling_window.lua
--[[ experimenting with a rolling frame for embeddings rather than individual words.
      will need a lean way to store the data
]]

local function insert_nested(frames, frame)
  local current = frames  -- start at the top
  for _, key in ipairs(frame) do
    -- create or traverse the nest
    current[key] = current[key] or {} 
    -- move further into the nest
    current = current[key]
  end
  -- last key gets the value, this could be the embedded vector
  -- local count = current[current] or 1
  -- current[current] = count + 1
end


local function frame_words(message, frames)
  if message and message ~= "" then
    local frame_size = 3
    local words = {}
    message:gsub("%a+", function(word)
      table.insert(words, word)
    end)

    if not words or #words < 1 then
      return nil
    end

    frames = frames or {}

    for i = 1, (#words - math.min(#words, frame_size) + 1) do
      local frame = {table.unpack(words, i, i + math.min(#words, frame_size) - 1)}
      insert_nested(frames, frame)
    end

    return frames
  end
end
-- -- to iterate, for example
-- local function print_table(tbl)
--   local tmp = {}
--   for key, val in pairs(tbl) do
--       -- check if the value is a table first. 
--     if type(val) == "table" then
--       print(key)
--       print_table(val) -- recurse
--     else
--       io.write(table.concat(tmp, " "), val, "\n")
--     end
--   end
-- end
-- print_table(frames, " ")

return frame_words
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2025 monk (Discord ID: 699370563235479624)                         --
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