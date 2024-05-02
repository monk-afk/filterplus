    --==[[    FilterPlus - DEV    ]]==--
    --==[[  fplus_blackwhite.lua  ]]==--
    --==[[   MIT (c) 2023  monk   ]]==--
--[[
    For finding blacklisted words in the whitelist, run script in terminal:
        $ lua fplus_blackwhite.lua > blackwhite.txt
 ]]


local gsub   = string.gsub
local lower  = string.lower
local concat = table.concat
local time   = os.time

local blacklist_file = "../blacklist.lua"
local whitelist_file = "../whitelist.lua"

local counts = {}
local blacklist = {}
local whitelist = {}
local bpatterns = {}

local function index_blacklist(word_array)
  for i = 1, #word_array do
    if not blacklist[word_array[i]] then
      local pattern = "(%S*"
      for n = 1, #word_array[i] do
        local l = word_array[i]:sub(n,n)
        pattern = pattern .. "["..l..l:upper().."]+[%s%p]-"
      end
      bpatterns[#bpatterns+1] = pattern.."%S*)"
      blacklist[#bpatterns] = word_array[i]
    end
  end
  return
end

local function index_whitelist(word_array)
  for i = 1, #word_array do
    whitelist[word_array[i]] = word_array[i]
  end
  return 
end

local function filter_message(msg_block)
  if #msg_block[1] <= 1 then
    return
  end

  for i = 1, #bpatterns do
    gsub(gsub(msg_block[1], "[%(%)%.%-%*%+%?%[%]%^%$%%]", "%%%1"), bpatterns[i], function(context)
      whitelist[msg_block[1]] = blacklist[i]
      if counts[blacklist[i]] then
        counts[blacklist[i]] = counts[blacklist[i]] + 1
      else
        counts[blacklist[i]] = 1
      end
    end)
  end

end


local on_chat_message = function(message)
  filter_message({message})
	return true
end


index_blacklist(dofile(blacklist_file))

index_whitelist(dofile(whitelist_file))


--[[ Not used in this script, but useful for reading stdin ]]
  -- while true do
  -- 	local message = io.read("*line")
  -- -- print(message)
  -- 	if not message or message == "/q" then
  -- 		break 
  -- 	end
  -- --

-- filter the whitelist and reindexing with associated blacklist entry
local whites = dofile(whitelist_file)
for word = 1, #whites do
	on_chat_message(whites[word])
end

print("Whitelisted Word \t -> \t Filtered by Blacklisted")
for white, black in pairs(whitelist) do
  if white ~= black then
    print(white.."    \t-> \t "..black)
  end
end

for blacklisted, count in pairs(counts) do
  print(blacklisted.." = "..count)
end