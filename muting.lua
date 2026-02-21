core.register_privilege("mute", "Grants usage of mute and forceblock command.")

local muted_players = {
  -- ["1.1.1.1"] = 123123123,
  -- ["monk"] = "1.1.1.1"
}

local function is_player_muted(name)
  local speaker = muted_players[muted_players[name]]
  return speaker and speaker > os.time() -- true is muted
end

-- check for existing mutes against name and ip
local function sync_muted_player_onjoin(name)
  local join_ip = core.get_player_ip(name)
  local time_now = os.time()

  local last_ip = muted_players[name]
  local ip_timestamp = muted_players[join_ip] or time_now

  -- link player to IP if missing or changed
  if not last_ip or last_ip ~= join_ip then
    muted_players[name] = join_ip
  end

  -- resume paused mute (negative = remaining seconds)
  if ip_timestamp and ip_timestamp < 0 then
    muted_players[join_ip] = time_now - ip_timestamp
  else
    muted_players[join_ip] = math.max(ip_timestamp, time_now)
  end
end


local function sync_muted_player_onleave(name)
  local ip = muted_players[name]
  if not ip then return end

  local expiry = muted_players[ip]
  if not expiry then return end

  local time_now = os.time()
  if expiry > time_now then
    -- check if others share the same mute IP and are still online
    for pname, pip in pairs(muted_players) do
      if pname ~= name and pip == ip and core.get_player_by_name(pname) then
        return -- another muted player with same IP still online
      end
    end
    -- pause the mute by storing remaining seconds as negative
    muted_players[ip] = -(expiry - time_now)
  end
end

-- so i dont have to carry two references between files
local function sync_muted_pointer(name, onjoin)
  if onjoin then sync_muted_player_onjoin(name)
  else sync_muted_player_onleave(name)
  end
end


-- apply mute time against ip and any connected alt account
local function sync_mute_time_on_command(name, time)
  -- update the linked index with the new time
  local linked_ip = muted_players[name]
  muted_players[linked_ip] = time

  -- if name_or_ip is a player name, time_or_ip will be an IP.
  -- if name_or_ip is an ip address, time_or_ip will be a time.
  for name_or_ip, time_or_ip in pairs(muted_players) do
    -- if time_or_ip is a unix timestamp, this will be nil
    local cached_ip_link = muted_players[time_or_ip]
    local indexed_ip_timestamp = muted_players[cached_ip_link]

    if indexed_ip_timestamp and indexed_ip_timestamp + 86400 < os.time() then
      muted_players[name_or_ip] = nil
    end
  end
end


local function check_valid_name(name)
  if not name then
    return "#! Missing player name!"

  elseif not core.player_exists(name) then
    return "#! Player <" .. name .. "> does not exist."

  elseif not muted_players[name] then
    return "#! <" .. name .. "> has not recently been online."
  end
end


core.register_chatcommand("mute", {
  description = "Mutes a player for a maximum of 120 minutes. Optional parameter default 2 minutes.",
  params = "<player_name> [minutes]",
  privs = {mute = true},
  func = function(user, param)
    local param = {param:match("^([a-zA-Z0-9_-]+)%s*(%d*)%s*(.*)$")}
    local name = param[1]

    local not_valid_name = check_valid_name(name)
    if not_valid_name then
      return false, not_valid_name
    end

    local minutes = math.min((tonumber(param[2]) or 2), 120)

    local reason = param[3] and param[3] ~= ""
        and ", with reason: " .. param[3] or "."

    local full_message = string.format("<%s> has been silenced for %d minutes%s", name, minutes, reason)

    core.chat_send_all("#! " .. full_message)
    core.log("action", "[Report] " .. full_message)

    sync_mute_time_on_command(name, os.time() + minutes * 60)
  end
})


core.register_chatcommand("unmute", {
  description = "Revoke a mute, allowing the player to chat in public.",
  params = "<player_name>",
  privs = {mute = true},
  func = function(user, param)
    local name = param:match("([a-zA-Z0-9_-]+)")

    local not_valid_name = check_valid_name(name)
    if not_valid_name then
      return false, not_valid_name
    end

    if not is_player_muted(name) then
      return false, "#! <" .. name .. "> is not currently muted."
    end

    local full_message = string.format("<%s> mute removed early by %s", name, user)

    core.chat_send_all("#! " .. full_message)
    core.log("action", "[Report] " .. full_message)

    sync_mute_time_on_command(name, os.time() - 1)
  end
})

return is_player_muted, sync_muted_pointer
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
