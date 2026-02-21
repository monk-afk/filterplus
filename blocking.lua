
local player_blocklist = {}

local function block_player(user, blocked_name)
  if not player_blocklist[user] then
    player_blocklist[user] = {}
  end

  player_blocklist[user][blocked_name] = true

  return "#! " .. user .. " is now blocking " .. blocked_name
end


local function unblock_player(user, blocked_name)
  if player_blocklist[user] and player_blocklist[user][blocked_name] then
    player_blocklist[user][blocked_name] = nil
  end

  if player_blocklist[user] and not next(player_blocklist[user]) then
    player_blocklist[user] = nil
  end

  return "#! " .. user .. " allowing chats from " .. blocked_name
end


local function get_blocklist(name)
  local blocklist = player_blocklist[name]
  if blocklist and next(blocklist) then
    local blocks = {}
    for blocked_name,_ in pairs(blocklist) do
      table.insert(blocks, blocked_name)
    end
    return "#! <" .. name .. ">'s Block list: " .. table.concat(blocks, ", ")

  else
    return "#! <" .. name .. ">'s Block list: No Players Blocked!"
  end
end


local function check_invalid_names(user, blocked_name)
  -- fail check if this function returns anything besides false or nil
  if not user then
    return "#! Please include a Player Name!"

  elseif not blocked_name or blocked_name == "" or user == blocked_name then
    return get_blocklist(user)

  elseif not core.player_exists(blocked_name) then
    return "#! Player <" .. blocked_name .. "> does not exist."

  elseif not core.player_exists(user) then
    return "#! Player <" .. user .. "> does not exist."

  elseif core.check_player_privs(blocked_name, "staff") then
    return "#! Staff cannot be blocked."
  end
  -- returned nil allows the caller to continue
end

core.register_chatcommand("block", {
  description = "Block player chats or view block list",
  params = "<player_name>",
  privs = {shout = true},
  func = function(user, param)
    local blocked_name = param:match("^([a-zA-Z0-9_-]+)$") or user

    -- staff priv allows viewing another player's blocklist
    if core.check_player_privs(user, "staff") then
      return true, check_invalid_names(blocked_name)
    else
      return true, check_invalid_names(user, blocked_name) or block_player(user, blocked_name)
    end
  end
})

core.register_chatcommand("unblock", {
  description = "Remove a player from your blocklist",
  params = "<player_name>",
  privs = {shout = true},
  func = function(user, param)
    local blocked_name = param:match("^([a-zA-Z0-9_-]+)$") or user

    -- staff priv allows viewing another player's blocklist
    if core.check_player_privs(user, "staff") then
      return true, check_invalid_names(blocked_name)
    else
      return true, check_invalid_names(user, blocked_name) or unblock_player(user, blocked_name)
    end
  end
})

core.register_chatcommand("forceblock", {
  description = "Block two players from chatting each other",
  params = "<player_name> <player_name>",
  privs = {mute = true},
  func = function(user, param)
    local name_one, name_two = param:match("([a-zA-Z0-9_-]+)%s*([a-zA-Z0-9_-]*)")

    if core.check_player_privs(user, "staff") and
        core.check_player_privs(name_two, "staff") then
      name_one, name_two = name_two, name_one
    end

    return true, check_invalid_names(name_one, name_two) or
        block_player(name_one, name_two) and block_player(name_two, name_one)
  end
})

core.register_chatcommand("forceunblock", {
  description = "Unblock two players allowing chat with each other",
  params = "<player_name> <player_name>",
  privs = {mute = true},
  func = function(user, param)
    local name_one, name_two = param:match("([a-zA-Z0-9_-]+)%s*([a-zA-Z0-9_-]*)")

    if core.check_player_privs(name_two, "staff") then
      name_one, name_two = name_two, name_one
    end

    return true, check_invalid_names(name_one, name_two) or
        unblock_player(name_one, name_two) and unblock_player(name_two, name_one)
  end
})


local function blocking_messages(sender, receiver)
  if (player_blocklist[sender] and player_blocklist[sender][receiver]) or
      (player_blocklist[receiver] and player_blocklist[receiver][sender]) then
    return true
  end
  return false
end

return blocking_messages
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2023-2026 monk (https://github.com/monk-afk)                       --
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
