  --[[  Chat Filter (Lua Port)  ]]--
  --[[   // monk @ SquareOne    ]]--
  --[[   init.lua - dev_0.0x    ]]--
  --[[     Licensed by CC0      ]]--

-- dump update because i'm pivoting away from trying to match evasion techniques
-- it's not worth the cpu time to check for all the evasion techniques.
local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub
local rep = string.rep


local filter = {
	blacklist = {},
}
local blacklist = filter.blacklist

local blacklist_file = "blacklist.lua"

local index_lists = function()
	local blacklist_items = dofile(blacklist_file)

	return blacklist_items
end

local blacklist_items = index_lists()

local index_filter = function()
	for i, listed_item in pairs(blacklist_items) do
		local head = match(blacklist_items[i], "^%S")
		local tail = match(blacklist_items[i], "%S$")

		if not blacklist[tail] then
			blacklist[tail] = {}
		end

		if not blacklist[tail][head] then
			blacklist[tail][head] = {}
		end

		table.insert(blacklist[tail][head], listed_item)
	end

	return filter
end
index_filter()


local function try_blacklist(word)
	local tail = match(word, "%S$")
	local head = match(word, "^%S")

	local blacklist_keys = blacklist[tail] and blacklist[tail][head]

	if blacklist_keys then
		for n = 1, #blacklist_keys do
			if word == blacklist_keys[n] then
				word = string.rep("*", word:len())

				return word
			end
		end
	end
	return word
end


local function remove_links(string)
	return gsub(string, "(h*t*t*p*s*:*/*/*%S+%./*%S*)", "(%1)")
end


-- local function remove_nonalpha(split_string)
-- 		-- return gsub(string, "[^%sa-zA-Z]", "")

-- 	for n = 1, #split_string do

-- 	end

-- 	return
-- end


local function remove_repeats(word_table)
	for n = 1, #word_table do
		local no_repeats = {}
		for c = 1, #word_table[n] do
		if not no_repeats[n] then
			no_repeats[n] = ""
		end
			local alpha = string.sub(word_table[n], c, c)
			local beta = string.sub(word_table[n], c+1, c+1)
			if alpha ~= beta then
				no_repeats[n] = no_repeats[n] .. alpha
			end
		end
		word_table[n] = no_repeats[n]
	end

	return word_table
end


local merge_gaps = function(word_table)
	local words, i = {}, 1
	for n = 1, #word_table do
		if not words[n] then
			words[n] = ""
		end

		if not word_table[i] then
			break
		end

		local c = 0
		if #word_table[i] == 1 then
			for b = i,#word_table do
				if #word_table[b] ~= 1 then
					break
				end
				words[n] = words[n] .. word_table[b]
				c = c + 1
			end
		else
			words[n] = word_table[i]
			c = c + 1
		end
		i = i + c
	end
	return words
end


local function make_word_table(string)
	local word_table, n = {}, 1

	gsub(string, "%S+", function(word)
		if not word_table[n] then
			word_table[n] = ""
		end
		
		word_table[n] = word
		n = n + 1
	end)
	return word_table
end


local fakechat = "fakechat.txt"  -- Replace with input stream from here
local function simulate_chat()

	local function file_exists(file)
		local f = io.open(file,"rb")
		if f then f:close() end
		return f~=nil
	end

	if not file_exists(fakechat) then
		return
	end

	for message in io.lines(fakechat) do  -- replace fakechat with real chat
		print(os.date("%b-%d %H:%M:%S"))
		local string = message --:lower()

		if string:len() > 28 then
			string:lower()
		end

		string = remove_links(string)

		local word_table = {}
		word_table = make_word_table(string)
		-- 
		-- merge_gaps and remove_repeats don't work the best together
		word_table = merge_gaps(word_table)
		word_table = remove_repeats(word_table)


		return table.concat(word_table, " ")
	end
end


local send_message = simulate_chat()

print("X: "..send_message)
