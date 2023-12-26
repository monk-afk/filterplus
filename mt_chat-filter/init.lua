  --[[  Chat Filter (Minetest)  ]]--
  --[[   // monk @ SquareOne    ]]--
  --[[   init.lua - dev_0.07    ]]--
  --[[     Licensed by MIT      ]]--
local modpath = minetest.get_modpath(minetest.get_current_modname())
local storage = minetest.get_mod_storage()

local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub
local rep = string.rep
local sub = string.sub
local max = math.max

local filter = {
	blacklist = {},
	players_online = {},
}
local blacklist = filter.blacklist
local players_online = filter.players_online
local blacklist_file = modpath.."/blacklist.lua"

local function load_blacklist()
	-- try to get blacklist from mod_storage
	local blacklist_items = minetest.deserialize(storage:get_string("blacklist"))
	if type(blacklist_items) ~= "table" then
	-- if it does not exist, construct blacklist from lua file
		blacklist_items = dofile(blacklist_file)
		if type(blacklist_items) ~= "table" then
			blacklist_items = {}
		end
	end
    return blacklist_items
end

local blacklist_items = load_blacklist()

local function save_blacklist_items()
    if type(blacklist_items) == "table" then
        storage:set_string("blacklist", minetest.serialize(blacklist_items))
    end
end
save_blacklist_items()


-- local index_lists = function()
-- 	local blacklist_items = dofile(blacklist_file)

-- 	return blacklist_items
-- end

-- local blacklist_items = index_lists()

local index_blacklist = function()
	for i, listed_item in pairs(blacklist_items) do
		local index = #blacklist_items[i]
		local head = sub(blacklist_items[i], 1, 1)
		local tail = sub(blacklist_items[i], -1)

		if not blacklist[index] then
			blacklist[index] = {}
		end

		if not blacklist[index][tail] then
			blacklist[index][tail] = {}
		end

		if not blacklist[index][tail][head] then
			blacklist[index][tail][head] = {}
		end

		table.insert(blacklist[index][tail][head], listed_item)
	end
	return filter
end
index_blacklist()


local function try_blacklist(try_word)
	local word = gsub(lower(try_word), "[^a-zA-Z]", "")

	local index = #word

	if index <= 1 then
		return word
	end

	local head = sub(word, 1, 1)
	local tail = sub(word, -1)
	local blacklist_keys = blacklist[index][tail] and blacklist[index][tail][head]

	if blacklist_keys then
		for n = 1, #blacklist_keys do
			if word == blacklist_keys[n] then
				word = rep("*", #blacklist_keys[n])
				return word
			end
		end
	end
	return try_word
end


local function remove_links(string)
	return gsub(string, "h*t*t*p*s*:*/*/*%S+%.+%S+%.*%S%S%S?/*%S*%s?", "")
end

local function make_word_table(string)
	local word_table, n = {}, 1

	gsub(string, "%S+", function(word)
		if not word_table[n] then
			word_table[n] = ""
		end
		
		word_table[n] = word
		n = n + 1
	end)
	return word_table
end


local color = minetest.colorize
local send_all = minetest.chat_send_all
local send_player = minetest.chat_send_player
-- local send_log = minetest.log --minetest.log("action","[Filter] "..text)
local max_caps = 32
local cc = {
	red		= "#C10023",  beta	= "#FACE23",
	dark 	= "#888888",
	orange	= "#DEAD23",
	green	= "#02BB20	",
	blue	= "#0099FF",
	cyan	= "#0CBBBD",
	pink	= "#FF00CC",
	white	= "#FFFFFF",
}
local stag = " # "..color(cc.red,"Square")..color(cc.dark,"One").." > "
local mtag = " # "..color(cc.orange, "Chat Filter").." > "
local ptag = function(name) return "<"..name.."> " end


local function send_message(message, sender, mentions)
	-- print(message, sender, mentions)
	if #mentions >= 1 then
		print(dump(players_online))
		for receiver,_ in pairs(players_online) do
			print(receiver)
			if mentions[receiver] then
				message = color(cc.green, message)
			end
			send_player(receiver, ptag(sender)..message)
		end
		return true
	end

	return send_all(ptag(sender)..message)
end


minetest.register_on_chat_message(function(name, message)
	-- check if player muted
	if players_online[name] >= os.time() then
		return true
	end

	local string = message
	if #string > max_caps then
		lower(string)
	end

	string = remove_links(string)

	local word_table = {}
	word_table = make_word_table(string)
	local a = 1
	local alpha = {}
	local omega = word_table
	local lambda = {}
	
	for o = 1, #word_table do
		if alpha[a] and #omega[o] > 1 then
			alpha[a] = nil 
			a = a + 1
		end

		if #omega[o] > 1 then
			lambda[a] = try_blacklist(omega[o])
			a = a + 1
		end

		if #omega[o] == 1 then
			alpha[a] = (alpha[a] or "") .. omega[o]
			lambda[a] = alpha[a]
		end

		if alpha[a] then
			lambda[a] = try_blacklist(alpha[a])
		end
	end

	local mentions = {}
	for word = 1,#lambda do
		gsub(lambda[word], "^([a-zA-Z0-9_-]+)@$", function(name)
			table.insert(mentions, name)
		end)
	end

	message = table.concat(lambda, " ")

	send_message(message, name, mentions)
	return true 
end)

--[[
	Chat commands:
	/mute <playername> [minutes]
	/unmute <playername>
	/blacklist <word>
]]

-- command to add word to blacklist
minetest.register_chatcommand("blacklist", {
    description = "Add word to chat filter blacklist",
	params = "<word>",
    privs = {server = true},
    func = function(name, params)
		if minetest.check_player_privs(name, {server = true}) then
			local word = params:match("(%S+)")

			if not word then
				return false, "Usage: /blacklist <word>"
			end
			table.insert(blacklist_items, word)
			save_blacklist_items()
			return send_player(name, mtag.."Added "..word.." to filter blacklist!")
		end
    end
})

-- mute player with /mute playnername timein minutes
minetest.register_chatcommand("mute", {
	description = "Mutes a player temporarily",
	params = "<player> (minutes)",
	privs = { mute = true },
	func = function(name, params)
		local playername, time = params:match("(%S+)%s+(%d*)")

		if not playername then
			return false, "Usage: /mute <player> (minutes)"
		end

		if time == 0 or time >= 60 then
			time = 600
		else
			time = time * 60
		end

		local mute_time = os.time() + time

		players_online[playername] = mute_time
	end,
})

minetest.register_chatcommand("unmute", {
	description = "Removes player mute",
	params = "<player>",
	privs = { mute = true },
	func = function(name, param)
		local playername = param:match("(%S+)%s+.+")

		if not playername then
			return false, "Usage: /unmute <player>"
		end

		local now_time = os.time()

		if players_online[playername] then
			players_online[playername] = mute_time
		else
			return false, "player <"..playername.."> is not muted"
		end
	end,
})


-- if player mute time is greater than current time, still muted
minetest.register_on_joinplayer(function(player)
	local name = player and player:get_player_name()
	if not name then return end

	local now_time = os.time()
	
	if not players_online[name] then
		players_online[name] = now_time
	else
		if players_online[name] < now_time then
			players_online[name] = nil
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player and player:get_player_name()
	if not name then return end

	local now_time = os.time()

	if players_online[name] and players_online[name] < now_time then
		players_online[name] = nil
	end
end)


-- remove any expired entries
local function save_daemon()
	local now_time = os.time()
	for i = 1, #players_online do
		if players_online[i] < now_time then
			players_online[i] = nil
		end
	end 
	minetest.after(3600, save_daemon)
end
minetest.after(1200, save_daemon)
