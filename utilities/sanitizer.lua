-- FilterPlus
-- Copyright © 2026 monk (https://github.com/monk-afk)
-- SPDX-License-Identifier: MIT

local function join_spaced(og_str)
  local str = " " .. og_str .. " " -- pad string with spaces
  -- only capture from match
  local spaced_out = str:match("%G(%a%a?)[%g%G]+")

  if spaced_out then
    local merged = spaced_out -- becomes (letter)
    local function m(s) merged = s end -- needs to stay outside of the loop, otherwise is overwritten inside loop

    while true do
      -- first loop is only captured match
      local mstr = str:gsub("(" .. merged .. ")%G((%a%a?)%G)", function(a,s,b)
        m(a .. b) -- for each letter after (%1) concat (%1) and (%3) into scoped var 'merged'
        return a .. s -- mstr becomes (%1) and (%2) [removing uncaptured space]
      end)
      -- when modified string is the same as padded og string, we've merged everything possible
      if mstr ~= str then str = mstr else break end
    end
  end
  -- clip padded spaces if they still exist
  return str:match("^%s*(.-)%s*$")
end


local function reduce_repeating(str)
  str = str:gsub("%s%s+", " ")
  while true do -- aggressively reduce repeated character sets (max 2)
    local mstr = str:gsub("((%S+)%S*)%2(%1)", "%3")
    if mstr ~= str then str = mstr else break end
  end
  return str
end

local function clean_message(str)
  str = str:lower()
  str = join_spaced(str)
  str = reduce_repeating(str)
  return str:gsub("%s+", " ")
end

return clean_message
