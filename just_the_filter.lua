    --==[[    FilterPlus    ]]==--
  --==[[   init.lua   0.1.4   ]]==--
  --==[[  MIT (c) 2023  monk  ]]==--
--[[
  For those who want the filter without the additional functions,
  this file contains the base of the filtering.
  Runs in shell terminal
]]
local gsub   = string.gsub
local lower  = string.lower
local concat = table.concat

local players_online = {}

local blacklist_file = "./blacklist.lua"
local whitelist_file = "./whitelist.lua"

local bpatterns = {}
local blacklist = {}
local whitelist = {}

local function index_blacklist(word_array)
  for i = 1, #word_array do
    if not blacklist[word_array[i]] then
      local pattern = "(%S*"
      for n = 1, #word_array[i] do
        local l = word_array[i]:sub(n,n)
        pattern = pattern .. "["..l..l:upper().."]+[%A]-"
      end
      bpatterns[#bpatterns+1] = pattern.."%S*)"
      blacklist[word_array[i]] = #bpatterns
    end
  end
end

local function index_whitelist(word_array)
  for i = 1, #word_array do
    whitelist[word_array[i]] = word_array[i]
  end
end

local function filter_message(message)
  for i = 1, #bpatterns do
    gsub(gsub(message, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), bpatterns[i], function(context)
      context:gsub("([%S]+)", function(word)
        if not whitelist[gsub(word:lower(), "%A+", "")] then
          message = gsub(message, context, ("*"):rep(#context))
          return
        else
          return
        end
      end)
    end)
  end
  return message
end


local function check_word(string)
  local filter_string = filter_message(string)
  if filter_string == string then
    return print(filter_string) --, false -- not censored
  end
  return print(filter_string) --, true
end

local function on_chat_message(message)
  if #message < 2 then
    return true
  end
  check_word(message)
  -- filter_message(message)
  return true
end

index_blacklist(dofile(blacklist_file))
index_whitelist(dofile(whitelist_file))


while true do
	local message = io.read("*line")
  on_chat_message(message)
end
