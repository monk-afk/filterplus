  -- Chat Filter - init.lua
  --	dev_0.02 - by: monk
  -- 
local ln, wc, ps, pn, bl, osc = 0, 0, 0, 0, 0, os.clock()  -- benchmark timer and counters

local filter = {}
local blacklist = "blacklist.lua"
local fakechat = "./fakechat_small.txt"  -- 100 thousand lines, 1671071B
-- local fakechat = "./fakechat_large.txt"  -- 1 million lines, 16403433B

local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub


local index_blacklist = function(curses)
bl = #curses
	for i, curse in pairs(curses) do
		local head = match(curses[i], "^%S")
		local tail = match(curses[i], "%S$")

		if not filter[tail] then
			filter[tail] = {}
		end

		if not filter[tail][head] then
			filter[tail][head] = {}
		end

		table.insert(filter[tail][head], curse)
	end
	return filter
end
local curses = dofile(blacklist)
index_blacklist(curses)


local find_positive = function(head, word)
	local positive = {}

	for _,curse in pairs(head) do

		if curse == word then
			table.insert(positive, word)
		end
	end
	return positive
end

local find_potential = function(string)
	local potential

	for i = 1, #curses do
	local curse = curses[i]

		if string.find(string, curse) then
		potential = potential or {}
			if not potential[curse] then
				potential[curse] = {}
			end
			
			table.insert(potential[curse], line)
		end
	end
	return potential
end

local find_index = function(string)
	for word in string:gmatch("%S+") do
		wc = wc + 1
		if #word >= 2 then
			local tail = match(word, "%S$")

			if filter[tail] then
				local head = match(word, "^%S")
				head = filter[tail][head]
			
				if head then
					return find_positive(head, word)
				end
			end
		end
	end
end


local string_potential = function(message)
	string = lower(message):
		gsub("[^a-zA-Z]", ""):  -- all non-alphabetic
		gsub("([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"):  -- duplicate chars
		gsub("([%s%S])%1", "%1")  -- duplicates 2nd pass

	return find_potential(string)
end


local string_positive = function(message)
	string = lower(message):
		gsub("(%w+)", " %1 "): -- extra spaces
		gsub("^%s*(.-)%s*$","%1"):  -- padding
		gsub("[^%sa-zA-Z]", ""):  -- non-alphanumeric
		gsub("%s-(%w*)%s(%w)%s", "%1%2"):  -- 'w o r d g a p s'
		gsub("([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"):  -- dduuupplicaaates
		gsub("([%s%S])%1", "%1")  -- duplicates 2nd pass

	return find_index(string)
end


local function simulate_chat()

	local function file_exists(file)
		local f = io.open(file,"rb")
		if f then f:close() end
		return f~=nil
	end

	if not file_exists(fakechat) then
		return
	end


	local filtered_words = {
		pos = {}, pot = {},
	}

	for line in io.lines(fakechat) do
		ln = ln + 1

		local positive = string_positive(line)

		if positive then
			for i = 1, #positive do
				local curse = positive[i]
				
				if not filtered_words.pos[curse] then
					filtered_words.pos[curse] = 0
				end

				filtered_words.pos[curse] = filtered_words.pos[curse] + 1
			end
			ps = ps + #positive
		end


		local potential = string_potential(line)

		if potential then
			for curse in pairs(potential) do

				if not filtered_words.pot[curse] then
					filtered_words.pot[curse] = {}
				end

				table.insert(filtered_words.pot[curse], line)
			end
			pn = pn + 1
		end
	end
	return filtered_words
end


local filtered_words = simulate_chat()

local function positive_matches()
	print("Positive Matches:")
	for word, count in pairs(filtered_words.pos) do
		print("  "..word..": "..count)
	end
end
positive_matches()

local function potentials_found()
	print("\nPotentials Found:")
	for potential in pairs(filtered_words.pot) do
		print(potential.." = {")
		for count,message in pairs(filtered_words.pot[potential]) do
			print("   "..count.." {"..message.."},")
		end
		print("},\n")
	end
end
potentials_found()

print(
	"line count: "..ln.."\n"..
	"word count: "..wc.."\n"..
	"black list: "..bl.."\n"..
	"filter hit: "..ps.."\n"..
	"potentials: "..pn.."\n"..
	"clock time: "..tonumber(string.format("%.6f", os.clock() - osc)).."\n"
)
