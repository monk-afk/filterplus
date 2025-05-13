  --==[[ FilterPlus 0.2.0 ]]==--
  --==[[ monk © 2023-2025 ]]==--
local function distance(pos_a, pos_b)
	local x = pos_a.x - pos_b.x
	local y = pos_a.y - pos_b.y
	local z = pos_a.z - pos_b.z
	return math.sqrt(x * x + y * y + z * z)
end

local blocking_messages, get_player_tags, clean, filter

core.register_chatcommand("xm", {
  description = "Proximity Message Only players within 100 nodes can hear",
  params = "<message>",
  privs = {shout = true},
  func = function(sender_name, message)
    local message = filter(clean(message))

    if #message >= 2 then
      local connected_players = core.get_connected_players()
      local sender_pos = core.get_player_by_name(sender_name):get_pos()

      local formatted_message = string.format(
        "#/xm %s %s", get_player_tags(sender_name), core.colorize("#00EEAA", message)
      )

      for _, receiver_player in ipairs(connected_players) do
        local receiver_pos = receiver_player:get_pos()

        if distance(sender_pos, receiver_pos) <= 100 then
          local receiver_name = receiver_player:get_player_name()
          local send = not blocking_messages(sender_name, receiver_name) 
              and core.chat_send_player(receiver_name, formatted_message)
        end
      end
    end
  end
})


core.override_chatcommand("msg", {
	description = "Send a private message to a player",
	params = "<recipient_name> <message>",
	privs = {shout=true},
	func = function(sender, param)
		local receiver, message = param:match("^([a-zA-Z0-9_-]+)%s(.+)$")

		if not receiver or not message then
			return false, "#! Invalid usage, requires a <name> and the message."

    elseif not core.get_player_by_name(receiver) then
			return false, "#! <" .. receiver .. "> is not online."

		elseif not blocking_messages(sender, receiver) then
      core.chat_send_player(receiver, string.format(
        "#/pm «%s» %s", sender, core.colorize("#00EE00", message)
      ))
    end
    -- the sender isn't advised of a block if one exists, receives confirmation regardless
    return true, string.format("#/pm «%s» %s", sender, core.colorize("#EE0066", message))
	end
})


local function register_active_block_check(func_block_check, func_player_tags, func_clean, func_filter)
  blocking_messages = func_block_check
  get_player_tags = func_player_tags
  clean, filter = func_clean, func_filter
end

return register_active_block_check
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
