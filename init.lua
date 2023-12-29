  --[[      FilterPlus      ]]--
  --[[   init.lua - 0.010   ]]--
  --[[  monk (c) 2023 MITL  ]]--
minetest.register_privilege("mute", "Grants usage of mute command.")
minetest.register_privilege("blacklist", "Grants blacklist management.")

local modpath = minetest.get_modpath(minetest.get_current_modname())
local storage = minetest.get_mod_storage()

local factions_available = minetest.global_exists("factions")
local ranks_available = minetest.global_exists("ranks")
local exp_available = minetest.global_exists("exp")

local gmatch = string.gmatch
local concat = table.concat
local insert = table.insert
local match  = string.match
local lower  = string.lower
local gsub   = string.gsub
local time   = os.time
local rep    = string.rep
local sub    = string.sub

local send_player = minetest.chat_send_player
local send_all = minetest.chat_send_all
local send_log = function(text)
	return minetest.log("action","[Filter] "..text)
end

local color = minetest.colorize
local cc = {
	red		= "#CC2023",
	green	= "#23F00D",
	orange	= "#DEAD23",
	white	= "#FFFFFF",
}

local mod_tag = " # "..color(cc.orange, "Filter").." > "
local max_caps = 12


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


local function player_tags(name)
	local tags, n = {""}, 0

	if ranks_available then
		local rank_title, rank_color = ranks.get_player_rank(name)
		if rank_title then
			tags[#tags+1] = "{"..color(rank_color, rank_title).."}"
		end
	end

	if factions_available then
		local faction_name, faction_color = factions.is_player_in(name)
		if faction_name then
			tags[#tags+1] = "["..color(faction_color, faction_name).."]"
		end
	end

	if exp_available then
		tags[#tags+1] = "("..exp.get_player_exp(name)..")"
	end

	tags[#tags+1] = "<"..name.."> "

	return concat(tags)
end


local function send_message(message, sender, mentions)
	local message = concat(message, " ")
	local ptags = player_tags(sender)

	if mentions then
		for recipient,_ in pairs(players_online) do
			local msg_color = cc.white
				if mentions[recipient] then
					msg_color = cc.green
				end
			send_player(recipient, ptags..color(msg_color, message))
		end
		return
	end
	return send_all(ptags..message)
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


filterplus_api = {}
function filterplus_api.check_word(word)
local try_word = try_blacklist(word)
	if try_word == word then
		return false
	end
	return true, try_word
end


local function process_message(word_table, sender)
	local mentions
	local a = 1
	local alpha = {}
	local omega = word_table
	local lambda = {}
	
	for o = 1, #word_table do
			local name = gsub(word_table[o], "[^a-zA-Z0-9_-]*$", "")
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
			alpha[a]  = (alpha[a] or "") .. omega[o]
			lambda[a] =  alpha[a]
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
		return true, send_player(name, mod_tag..color(cc.red, "You are muted."))
	end

	local string = message
	if #string > max_caps then
		lower(string)
	end

	string = remove_links(string)

	local word_table = {}
	word_table = make_word_table(string)

	return true, process_message(word_table, name)
end)


minetest.register_chatcommand("blacklist", {
    description = "Manage filter blacklist",
	params = "<insert|remove> <word>",
    privs = {blacklist = true},
    func = function(name, params)
		if minetest.check_player_privs(name, {server = true}) then
			params = params:split(" ")
			local switch = params[1]
			local word = params[2]

			if not word or not switch then
				return send_player(name, mod_tag.."Usage: /blacklist <insert|remove> <word>")
			end

			local try_word = try_blacklist(word) or "*"

			if switch == "insert" then
				if try_word ~= word then
					return send_player(name, mod_tag.."Word "..word.." already blacklisted")
				end
				blacklist_items[#blacklist_items+1] = word

			elseif switch == "remove" then
				if try_word == word then
					return send_player(name, mod_tag.."Word "..word.." not found in blacklist")
				end

				for i = 1, #blacklist_items do
					if blacklist_items[i] == word then
						blacklist_items[i] = nil
					end
				end

			else
				return send_player(name, mod_tag.."please use 'insert' or 'remove'")
			end

			save_blacklist_items()
			blacklist = {}
			index_blacklist()

			return send_player(name, mod_tag.."Successful "..switch.." of: '"..word.."'")
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
			return send_player(name, mod_tag.."Player <"..playername.."> does not exist.")
		end

		if minutes > 120 then
			minutes = 120
		elseif minutes < 1 then
			minutes = 1
		end

		local seconds = (minutes * 60)

		local mute_time = time() + seconds

		players_online[playername] = mute_time

		send_log("[Report]: "..name.." muted "..playername.." for "..minutes.." minutes.")
		send_player(name, mod_tag.."Muted <"..playername.."> muted for "..minutes.." minutes.")
		send_player(playername, mod_tag.."You are muted for "..color(cc.red, minutes).." minutes.")
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
			send_player(name, mod_tag..playername.." mute removed.")
			send_player(playername, mod_tag.."You are not muted.")
		else
			return send_player(name, mod_tag..playername.." is not currently muted.")
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


minetest.log("action", "[FilterPlus] Loaded!")