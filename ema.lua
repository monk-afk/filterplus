  --==[[ FilterPlus 0.3.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
local function exponential_moving_average(init_threshold)
  -- inversely proportional to the delta between the current value and threshold
  local threshold = init_threshold
  local alpha_max = 0.00025 -- higher alpha = more reactive
  local alpha_min = 0.00005 --  lower alpha = more stability
  local curve     = 100     -- higher curve = more resistance

  return function(value)
    local delta = math.abs(value - threshold)
    local slope = (1 / (1 + curve * delta)) -- sigmoid-like curve
    local alpha = alpha_min + (alpha_max - alpha_min) * slope
    threshold = alpha * value + (1 - alpha) * threshold
    return threshold
  end
end

return exponential_moving_average
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (Discord ID: 699370563235479624)                    --
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