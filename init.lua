	--[[      Filter Plus      ]]--
	--[[   init.lua - 0.0.9    ]]--
	--[[  Lic.MIT(c)2023 monk  ]]--
minetest.register_privilege("mute", "Grants usage of mute command.")

local modpath = minetest.get_modpath(minetest.get_current_modname())
local storage = minetest.get_mod_storage()

local match = string.match
local gmatch = string.gmatch
local rep = string.rep
local lower = string.lower
local gsub = string.gsub
local sub = string.sub
local time = os.time
local concat = table.concat
local insert = table.insert

local color = minetest.colorize
local send_all = minetest.chat_send_all
local send_player = minetest.chat_send_player
local send_log = function(text) return minetest.log("action","[Filter] "..text) end

local max_caps = 12
local cc = {
	red		= "#C10023",
	dark 	= "#888888",
	orange	= "#DEAD23",
	green	= "#1EFF00",
	blue	= "#0099FF",
	cyan	= "#0CBBBD",
	pink	= "#FF00CC",
	white	= "#FFFFFF",
}

local stag = " # "..color(cc.red,"Square")..color(cc.dark,"One").." > "
local mtag = " # "..color(cc.orange, "Filter").." > "
local ptag = function(name) return "<"..name.."> " end

local filter = {
	blacklist = {},
	players_online = {},
}
local blacklist = filter.blacklist
local players_online = filter.players_online
local blacklist_file = modpath.."/blacklist.lua"

local function load_blacklist()
	local blacklist_items = minetest.deserialize(storage:get_string("blacklist"))

	if type(blacklist_items) ~= "table" then
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

		insert(blacklist[index][tail][head], listed_item)
	end
	return filter
end
index_blacklist()

local function send_message(message, sender, mentions)

	message = concat(message, " ")

	if mentions then
		for recipient,_ in pairs(players_online) do
			local msg_color = cc.white
			
				if mentions[recipient] then
					msg_color = cc.green
				end
			
			send_player(recipient, ptag(sender)..color(msg_color, message))
		end
		return
	end

	return send_all(ptag(sender)..message)
end

local function try_blacklist(try_word)
	local word = gsub(lower(try_word), "[^a-zA-Z]", "")

	local index = #word

	if index <= 1 then
		return try_word
	end

	local head = sub(word, 1, 1)
	local tail = sub(word, -1)

	if not blacklist[index] or
			not blacklist[index][tail] or
					not blacklist[index][tail][head] then
		return try_word
	end

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

local function sanitize_message(word_table, sender)
	local mentions
	local a = 1
	local alpha = {}
	local omega = word_table
	local lambda = {}
	
	for o = 1, #word_table do
			local name = gsub(word_table[o], ":?", "")
			local mentioned = players_online[name]
			if mentioned then
				if not mentions then
					mentions = {}
				end
				mentions[name] = true
			end

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
	return send_message(lambda, sender, mentions)
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


local on_chat_message = minetest.register_on_chat_message
on_chat_message(function(name, message)

	if players_online[name] >= time() then
		return true, send_player(name, mtag.."You are muted.")
	end

	local string = message
	if #string > max_caps then
		lower(string)
	end

	string = remove_links(string)

	local word_table = {}
	word_table = make_word_table(string)

	return true, sanitize_message(word_table, name)
end)


minetest.register_chatcommand("blacklist", {
    description = "Manage filter blacklist",
	params = "<insert|remove> <word>",
    privs = {server = true},
    func = function(name, params)
		if minetest.check_player_privs(name, {server = true}) then
			params = params:split(" ")
			local switch = params[1]
			local word = params[2]

			if not word or not switch then
				return send_player(name, mtag.."Usage: /blacklist <insert|remove> <word>")
			end

			local try_word = try_blacklist(word) or "*"

			if switch == "insert" then
				if try_word ~= word then
					return send_player(name, mtag.."Word "..word.." already blacklisted")
				end

				insert(blacklist_items, word)

			elseif switch == "remove" then
				if try_word == word then
					return send_player(name, mtag.."Word "..word.." not found in blacklist")
				end

				for i = 1, #blacklist_items do
					if blacklist_items[i] == word then
						blacklist_items[i] = nil
					end
				end
			else
				return send_player(name, mtag.."please use 'insert' or 'remove'")
			end

			save_blacklist_items()
			blacklist = {}
			index_blacklist()

			return send_player(name, mtag.."Blacklist entry "..word.." "..switch.."!")
		end
    end
})

minetest.register_chatcommand("mute", {
	description = "Mutes a player for a set time in minutes",
	params = "<player> [<minutes>]",
	privs = { mute = true },
	func = function(name, params)
		params = params:split(" ")
		local playername = params[1]
		local minutes = tonumber(params[2]) or 10

		if not playername then
			return false, "Usage: /mute <player> [<minutes>]"
		end

		if not minetest.player_exists(playername) then
			return send_player(name, mtag.."Player <"..playername.."> does not exist.")
		end

		if minutes > 120 then
			minutes = 120
		elseif minutes < 1 then
			minutes = 1
		end

		local seconds = (minutes * 60)

		local mute_time = time() + seconds

		players_online[playername] = mute_time
		send_log(name.." muted "..playername.." for "..minutes.." minues.")
		send_player(name, mtag..playername.." muted for "..minutes.." minutes.")
		send_player(playername, mtag.."You are muted for "..minutes.." minutes.")
	end,
})

minetest.register_chatcommand("unmute", {
	description = "Remove player mute",
	params = "<player>",
	privs = { mute = true },
	func = function(name, param)
		local playername = param:match("([a-zA-Z0-9_-]+)%s*.*")

		if not playername then
			return false, "Usage: /unmute <player>"
		end

		if players_online[playername] and players_online[playername] >= time() then
			players_online[playername] = time()
			send_player(name, mtag..playername.." mute removed.")
			send_player(playername, mtag.."You are not muted.")
		else
			return send_player(name, mtag..playername.." is not currently muted.")
		end
	end,
})


minetest.register_on_joinplayer(function(player)
	local name = player and player:get_player_name()
	if not name then return end

	if not players_online[name] then
		players_online[name] = time()
	else
		if players_online[name] < time() then
			players_online[name] = time()
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player and player:get_player_name()
	if not name then return end

	if players_online[name] and players_online[name] < time() then
		players_online[name] = nil
	end
end)


local player_by_name = minetest.get_player_by_name
local function expunge_daemon()
	for name, timestamp in pairs(players_online) do
		if timestamp < time() then
			if not player_by_name(name) then
				players_online[name] = nil
			end
		end
	end
	minetest.after(1800, expunge_daemon)
end
minetest.after(1800, expunge_daemon)