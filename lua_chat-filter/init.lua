  --[[  Chat Filter (Lua Port)  ]]--
  --[[   // monk @ SquareOne    ]]--
  --[[   init.lua - dev_0.05    ]]--
  --[[     Licensed by CC0      ]]--
local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub


local filter = {
	blacklist = {},
}
local blacklist = filter.blacklist

local blacklist_file = "blacklist.lua"

local index_lists = function()
	local blacklist_items = dofile(blacklist_file)

	return blacklist_items
end

local blacklist_items = index_lists()

local index_filter = function()
	for i, listed_item in pairs(blacklist_items) do
		local head = match(blacklist_items[i], "^%S")
		local tail = match(blacklist_items[i], "%S$")

		if not blacklist[tail] then
			blacklist[tail] = {}
		end

		if not blacklist[tail][head] then
			blacklist[tail][head] = {}
		end

		table.insert(blacklist[tail][head], listed_item)
	end

	return filter
end
index_filter()


local function remove_links(string)
	return gsub(string, "'https?://(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'", "")
end

local function remove_symbols(string)
	return gsub(string, "[^%sa-zA-Z]", "")
end

local function remove_space(string, trim)
	trim = trim and " " or ""
	return gsub(string, "%s+", trim)
end

local function remove_repeating(string)
	return gsub(string, "(%S%S+)%1", "%1")
end


local function match_keys_black(word)
	local tail = match(word, "%S$")
	local head = match(word, "^%S")

	if blacklist[tail] and blacklist[tail][head] then
		local black_keys = blacklist[tail][head]

		for _,listed_item in pairs(black_keys) do
			if word == listed_item then
				word = string.rep("*", word:len())

				return word
			end
		end
	end
	return word
end


local fakechat = "fakechat.txt"  -- Replace with input stream from here

local function chat_stream()

	local function file_exists(file)
		local f = io.open(file,"rb")
		if f then f:close() end
		return f~=nil
	end

	if not file_exists(fakechat) then
		return
	end

	for message in io.lines(fakechat) do  -- replace fakechat with real chat
		local filtered_message = message
		local string = filtered_message:lower()
		string = remove_links(string)
		string = remove_symbols(string)
		string = remove_space(string, true)
		-- string = remove_gaps(string)  -- needs fix
		string = remove_repeating(string)
	
		filtered_message = ""
	
		for word in string:gmatch("%S+") do
			if #word > 1 then
				word = match_keys_black(word)
			end

			filtered_message = filtered_message.." "..word
		end

		if filtered_message ~= message then
			message = filtered_message
		end

	return message
	end
end

local send_message = chat_stream()

print(send_message)