return function(b_grams, w_grams)
  return function(word)
    local word_len = #word

    if word_len > 1 then
      local sigma_black = 0
      local sigma_white = 0

      for pos = 1, word_len - 1 do
        local gram = word:sub(pos, pos + 1)
        local shifted_pos = (word_len - pos + 1) / word_len -- prefix adds more weight
        local weight = shifted_pos * #gram  -- gram position * length of gram

        local b = b_grams[gram] or 0
        sigma_black = sigma_black + (b * weight)

        local w = w_grams[gram] or 0.1
        sigma_white = sigma_white + (w * weight)
      end

      local frequency_bias = sigma_black / (sigma_white + 1)
      return frequency_bias
    end
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
