-- Mean Absolute Deviation
local function get_mad(vector)
  local mean = 0
  for i = 1, #vector do
    mean = mean + vector[i]
  end
  mean = mean / #vector
  local mad = 0
  for i = 1, #vector do
    mad = mad + math.abs(vector[i] - mean)
  end

  return (mad / #vector)
end

-- inversely proportional to the distance between the current MAD and the EMA threshold
local function get_alpha(delta, alpha_min, alpha_max, k)
  return alpha_min + (alpha_max - alpha_min) * (1 / (1 + k * delta))
end


local function update_ema_mad() -- EMA adjusted average
  local mad_threshold
  local alpha_max = 0.0085 -- higher alpha = more reactive
  local alpha_min = 0.0005 --  lower alpha = more stability
  local curve     = 100    -- higher curve = more resistance

  return function(vector)
    local new_mad_value = get_mad(vector)

    if not mad_threshold then
      mad_threshold = new_mad_value
    end

    local alpha = get_alpha(
        math.abs(new_mad_value - mad_threshold), alpha_min, alpha_max, curve)

    mad_threshold = alpha * new_mad_value + (1 - alpha) * mad_threshold

    return new_mad_value, mad_threshold
  end
end

return get_mad, update_ema_mad
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