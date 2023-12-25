  --[[  Chat Filter (Minetest)  ]]--
  --[[   // monk @ SquareOne    ]]--
  --[[   init.lua - dev_0.06    ]]--
  --[[     Licensed by CC0      ]]--
local modpath = minetest.get_modpath(minetest.get_current_modname())

local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub

local max_caps = 32


local filter = {
	blacklist = {},
}
local blacklist = filter.blacklist

local blacklist_file = modpath.."/blacklist.lua"

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
	return gsub(string, "[http]*[s]*[:/]*(%w[-.%w]*%.).+([.%S%S]*%S*)", "")
end

local function remove_symbols(string)
	return gsub(string, "[^%sa-zA-Z]", "")
end

local function remove_space(string, trim)
	trim = trim and " " or ""
	return gsub(string, "%s+", trim)
end

local function remove_repeating(string)
	return gsub(string,"([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"):
			gsub("([%s%S])%1", "%1")
end


local function try_blacklist(word)
	local tail = match(word, "%S$")
	local head = match(word, "^%S")

	local blacklist_keys = blacklist[tail] and blacklist[tail][head]

	if blacklist_keys then
		for _,listed_item in pairs(blacklist_keys) do
			if word == listed_item then
				word = string.rep("*", word:len())

				return word
			end
		end
	end
	return word
end


local send_all = minetest.chat_send_all
local function send_message(message)
	send_all(message)
end


minetest.register_on_chat_message(function(name, message)
		local string = message:lower()

		string = remove_links(string)
		-- string = remove_gaps(string)  -- needs fix
		string = remove_repeating(string)
		

		local n, s = 1, {}
		local word, num = gsub(string:lower(), "%S+", 
		function(word)
			if #word > 1 then
				
				local no_symbol = gsub(word, "%A", "")	
				if no_symbol then
					word = try_blacklist(no_symbol)
				end

				if gsub(word, "(%S%S+)%1", "%1") then
					word = try_blacklist(word)
				end
				
				word = try_blacklist(word)
			end
			
			table.insert(s, n, word)
			n=n+1
		end)

		message = table.concat(s, " ")

	send_message(message)
	return true
end)


minetest.register_chatcommand("reindex", {
    description = "Reindex Chat Filter Wordlists",
    privs = {server = true},
    func = function(name)
		if minetest.check_player_privs(name, {server = true}) then
			index_filter()
			return minetest.chat_send_player(name, "Reindexed Filter List!")
		end
    end
})