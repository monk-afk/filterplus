-- pre-evaluate messages for faster training.
local function evaluate_messages(clip)

  io.write("Load blacklist closure\n"); io.stdout:flush()
  local blacklist_check = dofile(clip.util_blacklist)(clip)
  io.write("Load whitelist closure\n"); io.stdout:flush()
  local whitelist_check = dofile(clip.util_whitelist)(clip)
  io.write("Load sanitizer\n"); io.stdout:flush()
  local sanitize = dofile(clip.util_sanitizer)

  io.write("Assessing workload... "); io.stdout:flush()
  local total_lines = dofile(clip.util_line_count)(clip.corpus_messages)
  io.write("Total lines: ", total_lines, "\n"); io.stdout:flush()

  io.open(clip.lib_tokens, "w"):write(""):close()

  local flag_buffer = {}

  local token_file = io.open(clip.lib_tokens, "a")
  local token_buffer = {}

  local buffer_size = 51000
  local c = 0

  for line in io.lines(clip.corpus_messages) do
    c = c + 1
    local is_positive = false  -- true if censored by filter lists
    line = sanitize(line)

    if line and line ~= "" then
      for word in blacklist_check(line) do 
        if not whitelist_check(word) then
          flag_buffer[word] = flag_buffer[word] and flag_buffer[word] + 1 or 1
          is_positive = true
          -- break
        end
      end

      table.insert(token_buffer, tostring(is_positive) .. ":" .. line .. "\n")

      if #token_buffer >= buffer_size then
        token_file:write(table.concat(token_buffer))
        token_buffer = {}

        io.write(string.format("%.2f%%\n", (c / total_lines) * 100)); io.stdout:flush()
      end

      if not dofile(clip.run_signal) then break end
    end
  end

  if #token_buffer > 0 then
    token_file:write(table.concat(token_buffer))
  end
  token_file:close()

  local flag_file = io.open(clip.lib_evalflags, "a")
  for word, count in pairs(flag_buffer) do
    flag_file:write(word, " ", count, "\n")
  end
  flag_file:close()
end

return evaluate_messages



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