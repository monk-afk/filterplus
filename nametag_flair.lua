local factions_available = core.settings:get_bool("filterplus_factions") and
    core.global_exists("factions") == true
local get_player_faction = factions_available and factions.is_player_in or function() return nil end

local ranks_available = core.settings:get_bool("filterplus_ranks") and
    core.global_exists("ranks") == true
local get_player_rank = ranks_available and ranks.get_player_rank or function() return nil end

local exp_available = core.settings:get_bool("filterplus_exp") and
    core.global_exists("exp2_api") == true
local get_player_level = exp_available and exp2_api.get_player_exp_data or function() return nil end

local colorize = core.colorize

local function get_player_tags(name)
  local name_tag = "«" .. name .. "» "

  local rank_title, rank_color = get_player_rank(name)
  local rank_tag = rank_title and "{" .. colorize((rank_color or "#FFFFFF"), rank_title) .. "}" or ""

  local faction_name, faction_color = get_player_faction(name)
  local faction_tag = faction_name and "[" .. colorize((faction_color or "#FFFFFF"), faction_name) .. "]" or ""

  local player_level = get_player_level(name, "level")
  local level_tag = player_level and "(" .. math.floor(player_level) .. ")" or ""

  return string.format("%s%s%s%s", rank_tag, faction_tag, level_tag, name_tag)
end

return get_player_tags
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
