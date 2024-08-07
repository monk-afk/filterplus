  --==[[      FilterPlus      ]]==--
  --==[[   init.lua   0.1.4   ]]==--
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
-- when chat command to modify filter is used:
  -- if whitelist or blacklist word, add to mod_storage_black/whitelist, then reindex the blacklist/whitelist
  -- Same with delete
  -- For search, current method is fine.
  -- Save command should only save these tables to the mod_storage, not the file lists
  -- local mod_storage_blacklist = {}
  -- local mod_storage_whitelist = {}
  -- on initial load, mod_storage and file list to be merged as individual 'lists'


local function get_mod_storage_filter(listname)
  local list = minetest.deserialize(storage:get_string(listname))
  if type(list) ~= "table" or #list <= 0 then
    list = {}
  end
  return list
end


local function save_filter(listname, filter)
  if type(filter) ~= "table" then
    return minetest.log("warning",
      "FilterPlus could not save "..listname.." lists")
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
    if msg_block[3] then
        for name, player in pairs(players_online) do
            local msg_color = white
            local namelower = name:lower()
                if msg_block[3][name] then
                    msg_color = green
                end
            send_player(players_online[namelower].name, player_tags(msg_block[1])..colorize(msg_color, msg_block[2]))
        end
        return
    end
    return send_all(player_tags(msg_block[1])..msg_block[2])
end


local function mentioned_players(msg_block)
    gsub(msg_block[2], "[a-zA-Z0-9_-]+", function(word)
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


local function filter_message(msg_block)
    if #msg_block[2] <= 1 then
        return true
    end

    for i = 1, #bpatterns do
        gsub(gsub(msg_block[2], "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), bpatterns[i], function(context)
            context:gsub("([%S]+)", function(word)
                if not whitelist[gsub(word:lower(), "[%p%d]+", "")] then
                    msg_block[2] = gsub(msg_block[2], context, ("*"):rep(#context))
                    return
                else
                    return
                end
            end)
        end)
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
        table.remove(bpatterns, blacklist[word])
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


local player_ip = minetest.get_player_ip

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
    local params = {params:match("^([a-zA-Z0-9_-]+)%s*(%d*)")}
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

    send_player(user, mtag.."Muted <"..name.."> muted for "..minutes.." minutes.")
    send_player(name, mtag.."You are muted for "..colorize(red, minutes).." minutes.")

    minetest.log("action","[Filter] [Report]: "..user.." muted "..name.." for "..minutes.." minutes.")

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


local function add_player_online(player)
  local name = player and player:get_player_name()
  if not name then return end
  
  local namelower = name:lower()

  if not players_online[namelower] or players_online[namelower].time < os.time() then
    players_online[namelower] = {
      name = name,
      ip = player_ip(name),
      time = os.time()
    }
  end
  return namelower
end

minetest.register_on_joinplayer(function(player)
  return sync_time(add_player_online(player))
end)


local int = math.random(3500,3800)
local player_by_name = minetest.get_player_by_name
local function purge_offline()
  local time_past = os.time() + int
  for name, player in pairs(players_online) do
    if not player_by_name(player.name) then
      if player.time < time_past then
        players_online[name] = nil
      end
    end
  end
  minetest.after(int, purge_offline)
end
minetest.after(int, purge_offline)


 -- Filter saves are not automatic due to size
minetest.register_chatcommand("filter_save", {
	description = "Save Filter Lists Manually",
	params = "",
	privs = {server = true},
	func = function(name)
    save_filter(filter)
    send_player(name, mtag.."Filter Saved")
  end,
})

 -- Use this after editing the list files
minetest.register_chatcommand("filter_reload", {
	description = "Reloads Filter Lists",
	params = "",
	privs = {server = true},
	func = function(name)

    blacklist = {}
    index_blacklist(dofile(blacklist_file))
    index_blacklist(get_mod_storage_filter("blacklist"))

    whitelist = {}
    index_whitelist(dofile(whitelist_file))
    index_whitelist(get_mod_storage_filter("whitelist"))

    send_player(name, mtag.."Filters reloaded")
  end,
})

 -- Faster server boot time
minetest.register_on_mods_loaded(function()
  index_blacklist(dofile(blacklist_file))
  index_whitelist(dofile(whitelist_file))
end)