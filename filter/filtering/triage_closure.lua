-- approximate substring matches inside a given string
-- then dictionary strings that match the pattern approximately
return function(whitelist)
  return function(candidate_pool, sanitized_message)
    local candidates

    for blacklisted_word, pattern in pairs(candidate_pool) do
      local approximate_pattern = pattern.approximate
      local semantic_pattern = pattern.semantic

      for approximate_match in sanitized_message:gmatch(approximate_pattern) do
        if not whitelist[approximate_match] then

          for semantic_match in approximate_match:gmatch(semantic_pattern) do
            if semantic_match and not whitelist[semantic_match] then
              if not candidates then candidates = {} end

              table.insert(candidates, {
                  string_matched = semantic_match,
                  blacklisted_word = blacklisted_word,
                })
            end
          end
        end
      end
    end
    return candidates
  end
end
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
