-- track players with disabled chat, and quicker lookup for name mentions
local function register_online_players(sync_muted_pointer)
  local online_players = {}

  local function add_or_remove_online(player, status)
    local name = player and player:get_player_name()
    -- status is true or nil signaling event type
    online_players[name:lower()] = status and name or status
    sync_muted_pointer(name, status)
  end

  core.register_on_joinplayer(function(player)
    add_or_remove_online(player, true)
  end)

  core.register_on_leaveplayer(function(player)
    add_or_remove_online(player, nil)
  end)


  core.register_chatcommand("chat", {
    description = "Toggle public chat while still allowing private messages",
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
      return true, string.format("#! %s public chat.", status)
    end
  })

  return online_players
end

return register_online_players
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
