  --==[[ FilterPlus ]]==--
local modpath = core.get_modpath(core.get_current_modname()) .. "/"

-- player mentions highlight message in greentext
local find_mentioned_players = dofile(modpath .. "mentioning.lua")

-- nametag flair, ranks, level, faction
local get_player_tags = dofile(modpath .. "nametag_flair.lua")

-- block and forceblock
local blocking_messages = dofile(modpath .. "blocking.lua")

-- filtering API can be hot-swapped during run-time
local filter = dofile(modpath .. "filter_api.lua")(modpath)

-- muted players
local is_player_muted, sync_muted_pointer = dofile(modpath .. "muting.lua")

-- keep track of online players
local online_players = dofile(modpath .. "online_players.lua")(sync_muted_pointer)

-- private message override
dofile(modpath .. "messaging.lua")(blocking_messages)

local colorize = core.colorize

local function on_chat_message(sender_name, message)
  if is_player_muted(sender_name) then
    core.chat_send_player(sender_name, "#! You are muted.")
    return true
  end

  if not online_players[sender_name:lower()] then
    core.chat_send_player(sender_name, "#! Your chat is off. Use /chat to enable chat.")
    return true
  end

  local filtered_message = filter(message)

  if not filtered_message or #filtered_message < 2 then return true end

  local player_tags = get_player_tags(sender_name)

  local mentioned_players = find_mentioned_players(filtered_message, online_players)

  for receiver_name_lower, receiver_name in pairs(online_players) do
    if online_players[receiver_name_lower] then
      if not blocking_messages(sender_name, receiver_name) then
        local message_color = "#FFFFFF"

        if mentioned_players and mentioned_players[receiver_name_lower] then
          message_color = "#00EE00"
        end

        core.chat_send_player(receiver_name, player_tags .. colorize(message_color, filtered_message))
      end
    end
  end

  return true
end

core.register_on_chat_message(on_chat_message)

-- expose some API functions
filterplus = {}

-- returns the filtered string censored or not
filterplus.filter_check = function(str)
  return filter(str)
end

-- player nametag flare including rank, faction, exp if available
-- usage is simply get_player_tags(player_name)
filterplus.get_player_tags = get_player_tags


-- for mods providing chat functions to check if players are blocking eachother
-- usage: blocking_messages(player_a, player_b)
-- if sender blocked receiver or receiver blocked sender then returns true if blocked
filterplus.blocking_messages = blocking_messages



-- reload filter and reconstruct lists
core.register_chatcommand("filter_reload", {
  description = "Reload the chat filters",
  params = "",
  privs = {server = true},
  func = function(user)
    filter = dofile(modpath .. "filter_api.lua")(modpath)
    return true, "FilterPlus Reloaded!"
  end
})
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (https://github.com/monk-afk)                       --
--                                                                                --
-- Permission is hereby granted, free of charge, to any person obtaining a copy   --
-- of this software and associated documentation files (the "Software"), to deal  --
-- in the Software without restriction, including without limitation the rights   --
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      --
-- copies of the Software, and to permit persons to whom the Software is          --
-- furnished to do so, subject to the following conditions:                       --
--                                                                                --
-- The above copyright notice and this permission notice shall be included in all --
-- copies or substantial portions of the Software.                                --
--                                                                                --
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     --
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       --
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    --
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         --
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  --
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  --
-- SOFTWARE.                                                                      --
------------------------------------------------------------------------------------
