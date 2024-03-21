    --==[[       FilterPlus       ]]==--
    --==[[  cli_bench.lua  0.0.1  ]]==--
    --==[[   MIT (c) 2023  monk   ]]==--
dofile("dump.lua")
    --[[
        For use with Lua interactive in terminal,
                $ lua fpcli.lua

        Then type a message. No output on enther means string contains no blacklist words.


        For use with line feed from file,
                $ cat mytextfile.lua | lua fpcli.lua
        
        Comment-out the print lines to reduce output
    ]]

local gsub   = string.gsub
local lower  = string.lower
local concat = table.concat
local time   = os.time

local filter = {
    blacklist = {},
    whitelist = {}
}
local blacklist = filter.blacklist
local whitelist = filter.whitelist
local blacklist_file = "blacklist.lua"
local whitelist_file = "whitelist.lua"
local bpatterns = {}


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
    print(#word_array.." words Whitelisted")
    for i = 1, #word_array do
        whitelist[word_array[i]] = word_array[i]
    end
    return print("Loaded Whitelist")
end

local nice_words = dofile("nice_words.lua")
local matches = 0
local function filter_message(msg_block)
    if #msg_block[2] <= 1 then
        return true
    end
    for i = 1, #bpatterns do
        gsub(gsub(msg_block[2], "([%-])", "%%%1"), bpatterns[i], function(context)
            context:gsub("([%w]+)", function(word)

                if not whitelist[gsub(word:lower(), "[%p%d]+", "")] then
                    msg_block[2] = gsub(msg_block[2], context, nice_words[math.random(1, #nice_words)]) --("*"):rep(#word))
                    matches = matches + 1
                    print("Censored: "..word..": "..msg_block[2])
print(context, word)
                    -- minetest.log("action", "[Report]: Filtered: ["..context.."] In message: "..msg_block[2])
                else
                    print("Whitelisted: "..word..": "..msg_block[2])
                end
            end)
        end)
    end
    return
end


local on_chat_message = function(name, message)
    filter_message({name, message})
	return true
end


local function load_lists()
    if #blacklist <= 0 then
        index_blacklist(dofile(blacklist_file))
    end

    if #whitelist <= 0 then
        index_whitelist(dofile(whitelist_file))
    end
    return true
end
if load_lists() then
    print("Ready!")
end


local avg, ct, frq = 0, 0, 0

while true do
	local message = io.read("*line")
	if not message or message == "/q" then
		break 
	end
    
    frq = frq + 1

    local osc = os.clock()
	on_chat_message("monk", message)
    local oss = os.clock() - osc
    print("Clock: "..tonumber(string.format("%.6f", oss)))

    ct = ct + oss
end

avg = (ct/frq)
print("Iterations: "..frq, "Matches: "..matches)
print("Average clock: "..tonumber(string.format("%.6f", avg)))