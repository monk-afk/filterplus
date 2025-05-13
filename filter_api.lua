  --==[[ FilterPlus 0.2.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
local function whitelist_closure(modpath)
  local whitelist = {}
  for a, word in ipairs(dofile(modpath.."whitelist.lua")) do
    whitelist[word] = true
  end
  return function(word)
    return whitelist[word]
  end
end

local function blacklist_closure(modpath)
  -- build patterns for initial capture
  local blacklist_patterns_file = modpath .. "blacklist_patterns.lua"
  -- list of words for explicit comparison (no pattern)
  local blacklist_explicit_file = modpath .. "blacklist_explicit.lua"
  -- supplement explicit list with frequently mutated words
  local get_mutations = modpath .. "blacklist_mutations.lua"

  local blacklist_explicit = {}
  for n, word in ipairs(dofile(blacklist_explicit_file)) do
    blacklist_explicit[word] = true
  end

  for f, word in ipairs(dofile(get_mutations)()) do
    blacklist_explicit[word] = true -- "(" .. word:gsub(".", "%1+") .. ")"
  end

  -- loose pattern to capture context of flagged words
  local blacklist_patterns = {}
  for b, word in ipairs(dofile(blacklist_patterns_file)) do
    blacklist_patterns[word] = "(%a*%s?" .. word:gsub(".", "%1+%%s?") .. "%a*i*n*g*e*d*r*s*)"
  end

  -- for isolating the blacklisted word in the flagged context
  local blacklist_isolate = {}
  for s, word in ipairs(dofile(blacklist_patterns_file)) do
    blacklist_isolate[word] = ".*(%f[%a]%a-" .. word:gsub(".", "%1+") .. "%a-i*n*g*e*d*r*s*)%f[%A].*"
  end

  local whitelist_check = whitelist_closure(modpath)

  return function(message)
    return coroutine.wrap(function() 
      for blacklisted_word, pattern in pairs(blacklist_patterns) do
        for flagged_context in message:gmatch(pattern) do

          -- if we can isolate the curse word, it's likely a true positive
          local isolated_word = flagged_context:match(blacklist_isolate[blacklisted_word])
          if isolated_word and blacklist_explicit[isolated_word] then
            coroutine.yield(isolated_word)

            -- is the context a known vulgarity
          elseif blacklist_explicit[flagged_context] or
              blacklist_explicit[flagged_context:gsub("%s", "")] then
            coroutine.yield(flagged_context)

          else -- now check each word in the context
            for context_word in string.gmatch(flagged_context, "%a+") do
              -- if the context word has not been whitelisted
              if not whitelist_check(context_word) or
                  blacklist_explicit[context_word] then
                coroutine.yield(context_word)
              end
            end
          end
        end
      end
    end)
  end
end


local function filter_closure(modpath)
  local sanitizer = dofile(modpath .. "sanitizer.lua")
  local filter_message = blacklist_closure(modpath)

  return function(message)
    local sanitized_message = sanitizer(message)
    local is_censored
    if sanitized_message and sanitized_message ~= "" then
      for word in filter_message(sanitized_message) do
        sanitized_message = string.gsub(sanitized_message, word, ("*"):rep(#word))
        is_censored = true
      end
      message = is_censored and sanitized_message or message
    end
    return message, is_censored
  end
end


filterplus = {}

local function load_filter(modpath)
  local filter = filter_closure(modpath)
  -- api
  filterplus.filter_check = function(str)
    return filter(str)
  end

  return filter
end

return load_filter
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