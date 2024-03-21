    --==[[       FilterPlus       ]]==--
    --==[[     init.lua   0.1.2   ]]==--
    --==[[   MIT (c) 2023  monk   ]]==--
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

local send_player = minetest.chat_send_player
local send_all = minetest.chat_send_all
local colorize = minetest.colorize
local colorzen = modzen.color
local orange = colorzen.orange
local red = colorzen.red
local green = colorzen.green
local white = colorzen.white
local mtag = colorzen:mtag("Filter")

local gsub   = string.gsub
local lower  = string.lower
local concat = table.concat
local time   = os.time

local players_online = {}
local max_caps = 16

local filter
local blacklist_file = modpath.."blacklist.lua"
local whitelist_file = modpath.."whitelist.lua"


local function load_filter()
    filter = minetest.deserialize(storage:get_string("filterplus"))
    if type(filter) ~= "table" or #filter <= 0 then
        filter = {
            blacklist = {},
            whitelist = {}
        }
    end
    return filter
end
load_filter()


local function save_filter(filter)
    if type(filter) ~= "table" then
        return minetest.log("warning", "FilterPlus could not save filter lists")
    end
    storage:set_string("filterplus", minetest.serialize(filter))
    return filter
end


local blacklist = filter.blacklist
local bpatterns = {}
local whitelist = filter.whitelist

local function index_blacklist(word_array)
    print(#word_array.." words Blacklisted")
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
    return true
end

local function index_whitelist(word_array)
    for i = 1, #word_array do
        whitelist[word_array[i]] = word_array[i]
    end
    return filter
end


local function send_message(msg_block)
    if msg_block[3] then
        for name, player in pairs(players_online) do
            local msg_color = white
                if msg_block[3][name] then
                    msg_color = green
                end
            send_player(players_online[name].name, msg_block[1]..colorize(msg_color, msg_block[2]))
        end
        return
    end
    return send_all(msg_block[1]..msg_block[2])
end


local function player_tags(msg_block)
    local tags = {}
    -- these could be indexed in table instead of hitting with every msg
    if ranks_available then
        local rank_title, rank_color = ranks.get_player_rank(msg_block[1])
        if rank_title then
            tags[#tags+1] = "{"..colorize((rank_color or white), rank_title).."}"
        end
    end

    if factions_available then
        local faction_name, faction_color = factions.is_player_in(msg_block[1])
        if faction_name then
            tags[#tags+1] = "["..colorize((faction_color or white), faction_name).."]"
        end
    end

    if exp_available then
        tags[#tags+1] = "("..exp.get_player_exp(msg_block[1])..")"
    end

    tags[#tags+1] = "«"..msg_block[1].."» "
    msg_block[1] = concat(tags)
    return send_message(msg_block)
end


local function mentioned_players(msg_block)
    gsub(msg_block[2], "[a-zA-Z0-9_-]+", function(word)
        if players_online[word:lower()] then
            if not msg_block[3] then
                msg_block[3] = {}
            end
            msg_block[3][word] = players_online[word:lower()].name
        end
    end)
    return player_tags(msg_block)
end


local nice_words = dofile(modpath.."nice_words.lua")

local function filter_message(msg_block)

    if #msg_block[2] <= 1 then
        return true
    end

    for i = 1, #bpatterns do
        gsub(gsub(msg_block[2], "([%-])", "%%%1"), bpatterns[i], function(context)
            context:gsub("([%w]+)", function(word)

                if not whitelist[gsub(word:lower(), "[%p%d]+", "")] then
                    msg_block[2] = gsub(msg_block[2], context, nice_words[math.random(1, #nice_words)]) --("*"):rep(#word))
                    minetest.log("action", "[FilterPlus]: Blacklisted ["..context.."]")
                else
                    minetest.log("action", "[FilterPlus]: Whitelisted ["..context.."]")
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
local function remove_repeating(msg_block)
    msg_block[2] = msg_block[2]:gsub("(%S)%S+(%1)", "")  -- remove repeating
    return filter_message(msg_block)
end
]]

local function remove_hyperlink(message)
    return message:gsub("h*t*t*p*s*:*/*/*%S+%.+%S+%.*%S%S%S?/*%S*%s?", "")
end

local function remove_trailspace(message)
    return message:gsub("%s+", " ")
end


local on_chat_message = minetest.register_on_chat_message
on_chat_message(function(name, message)
    if not name then
        name = "monk"
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

        word = word:gsub("[%s%c]+", ""):gsub("%s+", " ")

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
        elseif list_type == "blacklist" then
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
    local mute_time = mute_time or time()
    for players, data in pairs(players_online) do
        if data.ip == players_online[name].ip then
            if mute_time > time() then -- mute players ip assoc
                data.time = mute_time
            elseif mute_time == 1 then -- unmute assoc
                data.time = time()
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
        params = {params:match("^([a-zA-Z0-9_-]+)%s*(%d*)")}

        if not params[1] then
            return false, "Usage: /mute <player> [<minutes>]"
        end

        if not minetest.player_exists(params[1]) then
            return send_player(user, mtag.."Player <"..params[1].."> does not exist.")
        end

        local minutes = math.min((tonumber(params[2]) or 2), 120)

        send_player(user, mtag.."Muted <"..params[1].."> muted for "..minutes.." minutes.")
        send_player(params[1], mtag.."You are muted for "..colorize(red, minutes).." minutes.")

        minetest.log("action","[Filter] [Report]: "..user.." muted "..params[1].." for "..minutes.." minutes.")

        return sync_time(params[1]:lower(), time() + minutes * 60)
    end,
})


minetest.register_chatcommand("unmute", {
    description = "Remove player mute",
    params = "<player>",
    privs = { mute = true },
    func = function(user, param)
        local playername = param:match("([a-zA-Z0-9_-]+)")

        if not playername then
            return false, "Usage: /unmute <player>"
        end

        local name = playername:lower()

        if players_online[name] and players_online[name].time <= time() then
            return send_player(user, mtag.."<"..playername.."> is not currently muted.")
        end
        
        send_player(user, mtag.."<"..playername.."> mute removed.")
        send_player(name, mtag.."You are not muted.")
        
        return sync_time(name, 1)
    end,
})


local function add_player_online(player)

    if not player:is_player() then
        return
    end
    local name = player:get_player_name()

    if not players_online[name] or players_online[name].time < time() then
        players_online[name:lower()] = {
            name = name,
            ip = player_ip(name),
            time = time()
        }
    end
    return name:lower()
end

minetest.register_on_joinplayer(function(player)
    return sync_time(add_player_online(player))
end)

local int = math.random(500,800)  -- Randomized to avoid sequencing mod functions
local player_by_name = minetest.get_player_by_name
local function purge_offline()
    for name, player in pairs(players_online) do
        if name ~= "monk" then
            if not player_by_name(player.name) then
                if player.time < time() then
                    players_online[name:lower()] = nil
                end
            end
        end
    end
    minetest.after(int, purge_offline)
end
minetest.after(int, purge_offline)


minetest.register_on_mods_loaded(function()
    if #blacklist <= 0 then
        index_blacklist(dofile(blacklist_file))
    end

    if #whitelist <= 0 then
        index_whitelist(dofile(whitelist_file))
    end
        players_online["monk"] = {
            name = "monk",
            ip = "localhost",
            time = time()
        }
end)

minetest.register_on_shutdown(function() 
    save_filter(filter)
end)

minetest.register_chatcommand("save_filter", {
	description = "Save Filter Lists Manually",
	params = "",
	privs = {server = true},
	func = function(name)
        save_filter(filter)
    end,
})

--==[[ ADD MONK TO CHAT ]]==--
minetest.register_chatcommand("monk", {
	description = "Add monk to chat",
	params = "<announce>",
	privs = {server = true},
	func = function(name, param)
        if param and type(param) == "boolean" then
            if param == true then
minetest.send_join_message("monk")
            else
minetest.send_leave_message("monk", false)
            end
        end

        players_online["monk"] = {
            name = "monk",
            ip = "localhost",
            time = time()
        }
        send_player(name, mtag.."Welcome to the chat, monk")
    end,
})