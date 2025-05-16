-- extracts the top 500 most commonly used words from the corpus

-- add to init.lua:
  -- clip.run_extract   = run_dir .. "extract_common.lua"     -- extract most common words
  -- elseif clip.extract then -- extract common words
  --   return dofile(clip.run_extract)(clip)
-- then run `lua init.lua extract`

-- todo: run through filter and limit words by length
local function extract_common_words(clip)
  local max_words = 500
  io.write("Load sanitizer\n"); io.stdout:flush()
  local sanitize = dofile(clip.util_sanitizer)

  io.write("Assessing workload... "); io.stdout:flush()
  local total_lines = dofile(clip.util_line_count)(clip.corpus_messages)

  io.write("Total lines: ", total_lines, "\n"); io.stdout:flush()
  local count = dofile(clip.util_counter)() -- local c = 0

  local vocabulary = {}
  local start_time = os.time()

  for line in io.lines(clip.corpus_messages) do
    local line = sanitize(line)
    if line and line ~= "" then
      for word in line:gmatch("%a+") do
        if not vocabulary[word] then
          vocabulary[word] = 1
        else
          vocabulary[word] = vocabulary[word] + 1
        end
      end

      local counted_lines = count() -- c = c + 1
      if counted_lines % 50000 == 0 then
        local elapsed_time = os.time() - start_time
        local lines_per_second = counted_lines / elapsed_time -- lines per second
        io.write(string.format("%s %8s/%s (%.02f%%) %.2f l/s\n",
            elapsed_time, counted_lines, total_lines, 
            (counted_lines / total_lines) * 100,
            lines_per_second))
        io.stdout:flush()
      end
    end
  end

  local sorted_vocab = {}

  for word, score in pairs(vocabulary) do
    table.insert(sorted_vocab, {
      word = word, score = score
    })
  end

  table.sort(sorted_vocab, function(a,b)
    return a.score > b.score
  end)

  local file = io.open(clip.lib_common_words, "w")

  local max = math.min(#sorted_vocab, max_words)

  file:write("return {\n")
  for n = 1, max do
    file:write(
      "[\"", sorted_vocab[n].word, "\"] = true,\n"
    )
  end

  file:write("}")
  file:close()

end

return extract_common_words
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
