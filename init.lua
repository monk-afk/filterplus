   --==[[     FilterPlus     ]]==--
  --==[[   init.lua   0.1.5   ]]==--
  --==[[  MIT (c) 2023  monk  ]]==--
minetest.register_privilege("mute", "Grants usage of mute command.")
minetest.register_privilege("blacklist", "Grants Filter-list management.")

local modpath = minetest.get_modpath(minetest.get_current_modname()).."/"
local storage = minetest.get_mod_storage()

local factions_available = minetest.settings:get_bool("filterplus_factions") and
  minetest.global_exists("factions") == true
local ranks_available = minetest.settings:get_bool("filterplus_ranks") and
  minetest.global_exists("ranks") == true
local exp_available = minetest.settings:get_bool("filterplus_exp") and
  minetest.global_exists("exp") == true
local max_caps = tonumber(minetest.settings:get("filterplus_max_caps")) or 16

local send_player = minetest.chat_send_player
local send_all    = minetest.chat_send_all
local colorize    = minetest.colorize

local orange = "#DDDD00"
local green  = "#00EE00"
local white  = "#FFFFFF"
local red    = "#FF0000"
local mtag   = "#[Filter] "

local gsub   = string.gsub
local lower  = string.lower
local concat = table.concat

local players_online = {}

local blacklist_file = modpath.."blacklist.lua"
local whitelist_file = modpath.."whitelist.lua"

local blacklist = {}
local bpatterns = {}
local whitelist = {}


local function get_mod_storage_filter(listname)
  local list = minetest.deserialize(storage:get_string(listname))
  if type(list) ~= "table" or #list <= 0 then
    list = {}
  end
  return list
end


local function save_filter(listname, filter)
  if type(filter) ~= "table" then
    minetest.log("warning", "FilterPlus could not save "..listname.." lists")
    return false
  end
  storage:set_string(listname, minetest.serialize(filter))
end


local function index_blacklist(word_array)
  for i = 1, #word_array do
    if not blacklist[word_array[i]] then
      local pattern = "(%S*"
      for n = 1, #word_array[i] do
        local l = word_array[i]:sub(n,n)
        pattern = pattern .. "["..l..l:upper().."]+[%s%p]-"
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


local function player_tags(name)
  local tags = {}
  -- tags could be indexed in online players table instead of hitting with every msg
  if ranks_available then
    local rank_title, rank_color = ranks.get_player_rank(name)
    if rank_title then
      tags[#tags+1] = "{"..colorize((rank_color or white), rank_title).."}"
    end
  end

  if factions_available then
    local faction_name, faction_color = factions.is_player_in(name)
    if faction_name then
      tags[#tags+1] = "["..colorize((faction_color or white), faction_name).."]"
    end
  end

  if exp_available then
    tags[#tags+1] = "("..exp.get_player_exp(name)..")"
  end

  tags[#tags+1] = "«"..name.."» "
  return concat(tags)
end


local function send_message(msg_block)
  local sender = msg_block[1]:lower()
  for receiver, player_data in pairs(players_online) do
    local msg_color = white

    if msg_block[3] and msg_block[3][receiver] then
      msg_color = green
    end

    if not (players_online[sender].blocklist and
        players_online[sender].blocklist[receiver]) and
        not (players_online[receiver].blocklist and
        players_online[receiver].blocklist[sender]) then

      send_player(player_data.name, player_tags(msg_block[1])..colorize(msg_color, msg_block[2]))
    end
  end
  return true
end



local function mentioned_players(msg_block)
  gsub(msg_block[2], "[a-zA-Z0-9_-]+", function(word)
      --[[ This is the only reason for lower-case of names.
          If there is not much difference use pairs traversal instead. ]]
    local namelower = word:lower()
    if players_online[namelower] then
      if not msg_block[3] then
        msg_block[3] = {}
      end
      msg_block[3][namelower] = players_online[namelower].name
    end
  end)
  return send_message(msg_block)
end


local accent_map = dofile(modpath.."accent_map.lua")
local function normalize_accents(str)
  return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
    return accent_map[c] or c
  end))
end


local function filter_message(msg_block)
  local sanitized_message = gsub(normalize_accents(msg_block[2]), "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
  local is_censored

  for i = 1, #bpatterns do
    gsub(sanitized_message, bpatterns[i], function(context)
      context:gsub("[%S]+", function(word)
        if not whitelist[gsub(word:lower(), "[%p%d]+", "")] then
          sanitized_message = gsub(sanitized_message, context, ("*"):rep(#context))
          is_censored = true
          return
        else
          return
        end
      end)
    end)
  end

  if is_censored then
    msg_block[2] = sanitized_message
  end

  if type(msg_block[1]) == "boolean" then
    return msg_block[2]
  end

  return mentioned_players(msg_block)
end


filterplus_api = {}
function filterplus_api.check_word(string)
  local filter_string = filter_message({true, string})
  if filter_string == string then
    return filter_string, false -- not censored
  end
  return filter_string, true
end


--[[  -- need a function to do this instead
local function remove_repeating(msg_block) -- for unnecessary repititions
  msg_block[2] = msg_block[2]:gsub("(%S)%S+(%1)", "")
  return filter_message(msg_block)
end
]]

local function remove_hyperlink(message)  -- sometimes gives false positive
  return message:gsub("h*t*t*p*s*:*/*/*%S+%.+%S+%.*%S%S%S?/*%S*%s?", "")
end

local function remove_trailspace(message)
  return message:gsub("%s+", " ")
end


local on_chat_message = minetest.register_on_chat_message
on_chat_message(function(name, message)
  if not name then
    return true
  end

  if players_online[name:lower()].time >= (os.time()) then
    return true, send_player(name, mtag..colorize(red, "You are muted."))
  end

  message = remove_trailspace(message)
  message = remove_hyperlink(message)

  if #message < 2 then
    return true
  end

  if #message > max_caps then
    message = message:lower()
  end

  filter_message({name, message})

  return true
end)


local function block_messages_from(blocked_name, name)
  if not minetest.player_exists(blocked_name) then
    return send_player(name, "Player does not exist")
  end

  local blocked_name = blocked_name:lower()
  local name = name:lower()
  if not players_online[name].blocklist then
    players_online[name].blocklist = {}
  end

  players_online[name].blocklist[blocked_name] = true

  return true
end


local function allow_messages_from(blocked_name, name)
  local blocked_name = blocked_name:lower()
  local name = name:lower()
  
  if players_online[name].blocklist
      and players_online[name].blocklist[blocked_name] then
    players_online[name].blocklist[blocked_name] = nil

    if #players_online[name].blocklist <= 0 then
      players_online[name].blocklist = nil
    end
  end
  return true
end


minetest.register_chatcommand("block", {
  description = "Block player chats, they wont hear you and you won't hear them",
  params = "<player>",
  privs = {shout = true},
  func = function(user, params)
    local blocked_name = params:match("^([a-zA-Z0-9_-]+)$")
    
    if not blocked_name or user == blocked_name then
      return send_player(user, mtag.."Usage: /block <player_name>")
    end

    if minetest.check_player_privs(user, "staff") or 
        minetest.check_player_privs(blocked_name, "staff") then
      return send_player(user, mtag.."Staff cannot block or be blocked!")
    end

    if not minetest.player_exists(blocked_name) then
      return send_player(user, mtag.."Player <"..blocked_name.."> does not exist.")
    end

    if block_messages_from(blocked_name, user) then
      send_player(user, mtag.."Player <"..blocked_name.."> has been blocked")
    else
      send_player(user, mtag.."Unable to add <"..blocked_name.."> to block-list!")
    end
  end
})

minetest.register_chatcommand("unblock", {
  description = "Remove player from your block-list",
  params = "<player>|<*>|<>",
  privs = {shout = true},
  func = function(user, params)
    local blocked_name = params:match("^(%*?[a-zA-Z0-9_-]*)$")

    if minetest.check_player_privs(user, "staff") or 
        minetest.check_player_privs(blocked_name, "staff") then
      return send_player(user, mtag.."Staff cannot block or be blocked!")
    end

    local lower_user = user:lower()
    
    if not players_online[lower_user].blocklist then
      return send_player(user, mtag.."Your block-list is empty!")
    end

    if blocked_name == "*" then
      -- clear the user's blocklist
      players_online[lower_user].blocklist = nil
      return send_player(user, mtag.."Your block-list has been cleared!")
    end

    if not blocked_name or blocked_name == "" then
      -- print a list of user's blocklist
      local tmp = {}
      for name,_ in pairs(players_online[lower_user].blocklist) do
        table.insert(tmp, name)
      end
      return send_player(user, mtag.."Players in your block-list: "..table.concat(tmp, ", "))
    end

    if not minetest.player_exists(blocked_name) then
      return send_player(user, mtag.."Player <"..blocked_name.."> does not exist.")
    end

    if not players_online[lower_user].blocklist[blocked_name] then
      return send_player(user, mtag.."Player <"..blocked_name.."> is not in your block-list")
      
    elseif players_online[lower_user].blocklist[blocked_name]
        and allow_messages_from(blocked_name, user) then
      return send_player(user, mtag.."Removed <"..blocked_name.."> from your block-list")

    else
      return send_player(user, mtag.."Unable to remove <"..blocked_name.."> from block-list!")
    end
  end
})


minetest.override_chatcommand("msg", {
	description = "Send a private message to a player",
	params = "<name> <message>",
	privs = {shout=true},
	func = function(name, param)
		local sendto, message = param:match("^(%S+)%s(.+)$")

		if not sendto then
			return false, "Invalid usage, do /msg <name> <message>."
		end

		if not minetest.get_player_by_name(sendto) then
			return false, "The player "..sendto.." is not online."
		end

    local l_sender, l_recip = name:lower(), sendto:lower()
    if (players_online[l_sender].blocklist and players_online[l_sender].blocklist[l_recip]) or
        (players_online[l_recip].blocklist and players_online[l_recip].blocklist[l_sender]) then
      return false, "Sender or Recipient has an active block-list"
    end

		minetest.chat_send_player(sendto, colorize(green, "PM <" .. name .. "> " .. message))
    minetest.chat_send_player(name, colorize(green, "PM TO: <" .. sendto .. "> " .. message))
		return true
	end,
})


minetest.register_chatcommand("filter", {
  description = "Manage filter blacklist",
  params = "<blacklist>|<whitelist>|<delete>|<search> <string>",
  privs = {blacklist = true},
  func = function(name, params)
  local list_type = params:match("^(blacklist)%s.+") or
    params:match("^(whitelist)%s.+") or
    params:match("^(delete)%s.+") or
    params:match("^(search)%s.+")

  if not list_type then
    return send_player(name, mtag..
    "Available filter commands: <whitelist>,<blacklist>,<delete>,<search>")
  end

  local word = params:match("^"..list_type.."%s(.+)")

  if not word then
    return send_player(name, mtag.."Usage: /"..command.." "..list_type.." <string>")
  end

  word = word:gsub("[%p%c%d]+", ""):gsub("%s+", " ")

  if list_type == "search" then
    local flag
    if blacklist[word] then
    send_player(name, mtag.."\""..word.."\"".." found in blacklist.")
    flag = true
    end

    if whitelist[word] then
    send_player(name, mtag.."\""..word.."\"".." found in whitelist.")
    flag = true
    end

    if not flag then
    send_player(name, mtag.."\""..word.."\"".." not found in filter lists.")
    end

    return
  end

  if list_type == "delete" then
    if blacklist[word] then
      blacklist[word] = nil
      index_blacklist(blacklist)
    elseif whitelist[word] then
      whitelist[word] = nil
      index_whitelist(whitelist)
    else
      return send_player(name, mtag.."Word "..word.." not found in list")
    end
  end

  if list_type == "whitelist" then
    if blacklist[word] then
      table.remove(bpatterns, blacklist[word])
      blacklist[word] = nil
    end
    if whitelist[word] then
      return send_player(name, mtag.."Word already whitelisted.")
    end
    index_whitelist({word})
  end

  if list_type == "blacklist" then
    whitelist[word] = nil
    if blacklist[word] then
      return send_player(name, mtag.."Word already blacklisted.")
    end
    index_blacklist({word})
  end

  return send_player(name, mtag.."Successful "..list_type.." of: '"..word.."'")
  end
})


local function sync_time(name, mute_time)
  local mute_time = mute_time or os.time()
  for players, data in pairs(players_online) do
    if data.ip == players_online[name].ip then
      if mute_time > os.time() then -- mute players ip assoc
        data.time = mute_time
      elseif mute_time == 1 then -- unmute assoc
        data.time = os.time()
      else -- join sync
        players_online[name].time = data.time
      end
    end
  end
end


minetest.register_chatcommand("mute", {
  description = "Mutes a player for time in minutes",
  params = "<player> [<minutes>]",
  privs = { mute = true },
  func = function(user, params)
  local params = {params:match("^([a-zA-Z0-9_-]+)%s*(%d*)%s*(.*)$")}
  if not params[1] then
    return false, "Usage: /mute <player> [<minutes>]"
  end

  local name = params[1]
  if not minetest.player_exists(name) then
    return send_player(user, mtag.."Player <"..name.."> does not exist.")
  end

  local namelower = name:lower()
  if not players_online[namelower] then
    return send_player(user, mtag.."<"..name.."> has not been recently online")
  end

  local minutes = math.min((tonumber(params[2]) or 2), 120)

  send_all(mtag.."<"..name.."> silenced for "..minutes.." minutes.")

  if params[3] and params[3] ~= "" then
    params[3] = ", with reason: "..params[3]
  end

  minetest.log("action","[Report] "..user.." muted "..name.." for "..minutes.." minutes"..params[3]..".")

  return sync_time(namelower, os.time() + minutes * 60)
  end,
})


minetest.register_chatcommand("unmute", {
  description = "Remove player mute",
  params = "<player>",
  privs = { mute = true },
  func = function(user, param)
  local name = param:match("([a-zA-Z0-9_-]+)")

  if not name then
    return false, "Usage: /unmute <player>"
  end

  local namelower = name:lower()

  if players_online[namelower] and players_online[namelower].time <= os.time()
    or not players_online[namelower] then
    return send_player(user, mtag.."<"..name.."> is not currently muted.")
  end

  send_player(user, mtag.."<"..name.."> mute removed.")
  send_player(name, mtag.."You are not muted.")

  return sync_time(namelower, 1)
  end
})

local player_ip = minetest.get_player_ip

local function add_player_online(player)
  local name = player and player:get_player_name()
  if not name then return end

  local namelower = name:lower()

  if not players_online[namelower] or players_online[namelower].time < os.time() then
  players_online[namelower] = {
    name = name,
    ip = player_ip(name),
    time = os.time(),
--    blocklist = {},
--    censor = true,
  }
  end
  return namelower
end

minetest.register_on_joinplayer(function(player)
  return sync_time(add_player_online(player))
end)

local admin = minetest.settings:get("name")
local int = math.random(3500, 3800)
local player_by_name = minetest.get_player_by_name
local function purge_offline()
  local time_past = os.time() + int
  for name, player in pairs(players_online) do
    if name ~= admin then
      if not player_by_name(player.name) then
        if player.time < time_past then
        players_online[name] = nil
        end
      end
    end
  end
  minetest.after(int, purge_offline)
end
minetest.after(int, purge_offline)


 -- Filter saves are not automatic due to size
minetest.register_chatcommand("filter_save", {
	description = "Save Filter Lists Manually",
	params = "<whitelist>|<blacklist>",
	privs = {server = true},
	func = function(name, filter)

    if filter == "blacklist" then
      local tmp = {}
      for word,_ in pairs(blacklist) do
        table.insert(tmp, word)
      end
      save_filter(filter, tmp)
      return send_player(name, mtag.."Filter "..filter.." Saved!")

    elseif filter == "whitelist" then
      local tmp = {}
      for word,_ in pairs(whitelist) do
        table.insert(tmp, word)
      end
      save_filter(filter, tmp)
      return send_player(name, mtag.."Filter "..filter.." Saved!")

    else
      return send_player(name, mtag.."Missing param: <blacklist> or <whitelist>")
    end    
  end
})

 -- Use this after editing the list files
minetest.register_chatcommand("filter_reload", {
	description = "Reloads Filter Lists from mod_storage or Lua file",
	params = "<mod_storage>|<file>",
	privs = {server = true},
	func = function(name, filter)
    if filter == "mod_storage" then
      blacklist = {}
      index_blacklist(get_mod_storage_filter("blacklist"))
      whitelist = {}
      index_whitelist(get_mod_storage_filter("whitelist"))
    elseif filter == "file" then
      blacklist = {}
      index_blacklist(dofile(blacklist_file))
      whitelist = {}
      index_whitelist(dofile(whitelist_file))
    else
      return send_player(name, mtag.."Usage: /filter_reload <mod_storage>|<file>")
    end

    send_player(name, mtag.."Filters reloaded! Use /filter_save to overwrite old mod_storage")
  end,
})

 -- Faster server boot time
minetest.register_on_mods_loaded(function()
  -- First try to load from modstorage
  index_blacklist(get_mod_storage_filter("blacklist"))
  index_whitelist(get_mod_storage_filter("whitelist"))

  -- fallback to using *list.lua
  if #whitelist == 0 then
    index_whitelist(dofile(whitelist_file))
  end

  if #blacklist == 0 then
    index_blacklist(dofile(blacklist_file))
  end

  players_online[admin:lower()] = {
    name = admin,  -- allows using console without crashing server
    ip = "0.0.0.0",
    time = 0
  }
end)