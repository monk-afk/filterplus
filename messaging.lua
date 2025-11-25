return function(blocking_messages)

  core.override_chatcommand("msg", {
    description = "Send a private message to a player",
    params = "<recipient_name> <message>",
    privs = {shout = true},
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
end
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
