local function register_on_chat(path)
  -- just incase
  if not path:match(".*/$") then path = path .. "/" end

  local filtering_path = path .. "filtering/"
  local wordlists_path = path .. "wordlists/"
  local utilities_path = path .. "utilities/"

  local module_files = {
    filtering_main = filtering_path .. "filtering_main.lua",
    triage_closure = filtering_path .. "triage_closure.lua",
    get_candidates = filtering_path .. "get_candidates.lua",

    frequency_bias   = utilities_path .. "frequency_bias.lua",
    edit_distance    = utilities_path .. "edit_distance.lua",
    root_sum_squared = utilities_path .. "root_sum_squared.lua",
    exponent_average = utilities_path .. "exponent_average.lua",
    sanitizer        = utilities_path .. "sanitizer.lua",

    blacklist = wordlists_path .. "blacklist.lua",
    whitelist = wordlists_path .. "whitelist.lua",
    blacklist_mutations = wordlists_path .. "blacklist_mutations.lua",
    construct_wordlists = wordlists_path .. "construct_wordlists.lua",
  }

  local filter = dofile(module_files.filtering_main)(module_files)

  return function(message)
    return filter(message)
  end
end

return register_on_chat
------------------------------------------------------------------------------------
-- MIT License                                                                    --
--                                                                                --
-- Copyright © 2026 monk (https://github.com/monk-afk)                            --
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
