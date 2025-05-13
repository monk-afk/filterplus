  --==[[ FilterPlus 0.2.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
-- track players with disabled chat, and quicker lookup for name mentions
local online_players = {}

local sync_muted_player_onjoin

local function add_or_remove_online(player, status)
  local name = player and player:get_player_name()
  -- if status = false, chat is disabled
  online_players[name:lower()] = status and name or status
  if status then
    sync_muted_player_onjoin(name)
  end
end

core.register_on_joinplayer(function(player)
  add_or_remove_online(player, true)
end)

core.register_on_leaveplayer(function(player)
  add_or_remove_online(player, nil)
end)


core.register_chatcommand("chat", {
  description = "Toggle public chat, allows private messages",
  params = "",
  privs = {shout = true},
  func = function(name)
    local name_lower = name:lower()
    local status
    if not online_players[name_lower] then
      online_players[name_lower] = name
      status = "Enabled"
    else
      online_players[name_lower] = false
      status = "Disabled"
    end
    return string.format("#! %s public chat.", status)
  end
})

-- register function from external file, and return the closure function to init.lua
local function load_sync_function(sync_muted_onjoin_func)
  sync_muted_player_onjoin = sync_muted_onjoin_func
  return function()
    return online_players
  end
end

return load_sync_function
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2025 monk (Discord ID: 699370563235479624)                    --
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
