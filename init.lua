  -- Chat Filter // monk @ SquareOne
  -- init.lua - dev_0.04
  -- Licensed by CC0
local path = minetest.get_modpath(
		minetest.get_current_modname())
local blacklist_file = path .."/blacklist.lua"
local whitelist_file = path .."/whitelist.lua"

local filter = {
	black = {},
	white = {},
}
local black = filter.black
local white = filter.white

local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub


local index_filter = function()
	
	local curses = dofile(blacklist_file)
	local cleans = dofile(whitelist_file)

	for i, curse in pairs(curses) do
		local head = match(curses[i], "^%S")
		local tail = match(curses[i], "%S$")

		if not black[tail] then
			black[tail] = {}
		end

		if not black[tail][head] then
			black[tail][head] = {}
		end

		table.insert(black[tail][head], curse)
	end

	
	for i, clean in pairs(cleans) do
		local head = match(cleans[i], "^%S")
		local tail = match(cleans[i], "%S$")

		if not white[tail] then
			white[tail] = {}
		end

		if not white[tail][head] then
			white[tail][head] = {}
		end

		table.insert(white[tail][head], clean)
	end

	return filter
end

index_filter()


local sanitize = function(string)
	return lower(string):
		gsub("(%w+)", " %1 "): -- extra spaces
		gsub("^%s*(.-)%s*$","%1"):  -- padding
		gsub("[^%sa-z]", ""):  -- non-alphanumeric
		gsub("([%S])%S+%1", "%1")  -- duplicated letters
end

minetest.register_on_chat_message(function(name, message)
	local string = sanitize(message)
	print(message)
	print(string)

	for word in string:gmatch("%S+") do
		if #word > 1 then
			local tail = match(word, "%S$")
			local head = match(word, "^%S")

			if white[tail] and white[tail][head] then
				local whitelist = white[tail][head]

				for _,clean in pairs(whitehead) do
					if clean == word then
						message = message
					end
				end

				minetest.chat_send_all(message)
				return true
			end

			if black[tail] and black[tail][head] then
				local blackhead = black[tail][head]

				for _,curse in pairs(blackhead) do
					if curse == word then

						message = gsub(message, word, string.rep("*", word:len()))	
					end
				end

				minetest.chat_send_all(message)
				return true
			end
		end
	end
end)


minetest.register_chatcommand("reindex", {
    description = "Reindex Chat Filter Wordlists",
    privs = {server = true},
    func = function(name)
        index_blacklist()
        minetest.chat_send_player(name, "Reindexed Filter List!")
    end
})