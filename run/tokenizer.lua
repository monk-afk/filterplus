-- pre-evaluate messages before training.
local function evaluate_messages(clip)
  local start_time = os.time()

  io.write("Load blacklist closure\n"); io.stdout:flush()
  local blacklist_check = dofile(clip.util_blacklist)(clip)

  io.write("Load sanitizer\n"); io.stdout:flush()
  local sanitize = dofile(clip.util_sanitizer)

  io.write("Assessing workload... "); io.stdout:flush()
  local total_lines = dofile(clip.util_line_count)(clip.corpus_messages)

  io.write("Total lines: ", total_lines, "\n"); io.stdout:flush()
  local count = dofile(clip.util_counter)() -- local c = 0

  local token_file = io.open(clip.lib_tokens, "r")
  if not token_file then
    io.open(clip.lib_tokens, "w"):write(""):close()
  else
    token_file:close()
  end

  local token_file = io.open(clip.lib_tokens, "a")
  local token_buffer = {}

  local buffer_size = total_lines * 0.01

  for line in io.lines(clip.corpus_messages) do
    local counted_lines = count() -- c = c + 1
    local line = sanitize(line)


    if line and line ~= "" then
    -- true if vulgar, false not vulgar, nil not processed (over sanitized)
      local is_positive = blacklist_check(line)
      if is_positive ~= nil then
        table.insert(token_buffer, string.format("%s:%s\n", tostring(is_positive), line))

        if #token_buffer >= buffer_size then
          token_file:write(table.concat(token_buffer))
          token_buffer = {}
          local elapsed_time = os.time() - start_time
          local lines_per_second = counted_lines / elapsed_time -- lines per second

          io.write(string.format("%s %8s/%s (%.02f%%) %.2f l/s\n",
              elapsed_time, counted_lines, total_lines, 
              (counted_lines / total_lines) * 100, lines_per_second))
          io.stdout:flush()
        end
      end

      if not dofile(clip.run_signal) then break end
    end
  end

  if #token_buffer > 0 then
    token_file:write(table.concat(token_buffer))
  end
  token_file:close()
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