  -- Chat Filter - init.lua.lua
  --	dev_0.03 - by: monk
  --[[ bug: if input has repeating blacklist words,
  		some are dropped between string_positive and find_positive ]]
local ln, wc, ps, pn, bl, osc = 0, 0, 0, 0, 0, os.clock()  -- benchmark timer and counters

local filter = {}
local blacklist = "blacklist.lua"
-- local fakechat = "smalllogs.txt"  -- 100 thousand lines, 1671071B
local fakechat = "testlogs.txt"  -- 1 million lines, 16403433B

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
			pn = pn + 1
		end
	end
	return potential
end


local find_positive = function(string)
	local positive = {}

	for word in string:gmatch("%S+") do
		wc = wc + 1
		if #word > 1 then
			local tail = match(word, "%S$")
			local head = match(word, "^%S")

			if filter[tail] and filter[tail][head] then
				local head = filter[tail][head]

				for _,curse in pairs(head) do
					if curse == word then
						table.insert(positive, word)

						ps = ps + 1
					end
				end
			end
		end
	end
	return positive
end


local string_potential = function(message)
	return find_potential(lower(message):
		gsub("[^a-zA-Z]", ""):  -- all non-alphabetic
		gsub("([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"):  -- duplicate chars
		gsub("([%s%S])%1", "%1"))  -- duplicates 2nd pass

end


local string_positive = function(string)
	return find_positive(lower(string):
		gsub("(%w+)", " %1 "): -- extra spaces
		gsub("^%s*(.-)%s*$","%1"):  -- padding
		gsub("[^%sa-zA-Z]", ""):  -- non-alphanumeric
		gsub("%s-(%w*)%s(%w)%s", "%1%2"):  -- 'w o r d g a p s'
		gsub("([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"):  -- dduuupplicaaates
		gsub("([%s%S])%1", "%1"))  -- 2nd pass for dupes

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
		positive = {}, potential = {},
	}


	for line in io.lines(fakechat) do
		ln = ln + 1

		local positive = string_positive(line)

		if positive then
			for i = 1, #positive do
				local curse = positive[i]
				
				if not filtered_words.positive[curse] then
					filtered_words.positive[curse] = {}
				end

				table.insert(filtered_words.positive[curse], line)
			end
		end


		-- local potential = string_potential(line)

		if potential then
			for curse in pairs(potential) do

				if not filtered_words.potential[curse] then
					filtered_words.potential[curse] = {}
				end

				table.insert(filtered_words.potential[curse], line)
			end
		end
	end
	return filtered_words
end


local filtered_words = simulate_chat()


	-- formatted for terminal output > file
local function positive_matches()
	print("    positive = {")

	for positive in pairs(filtered_words.positive) do
		print("        [\""..positive.."\"] = {")

		for count, message in pairs(filtered_words.positive[positive]) do
			print("            \""..gsub(message, "\"", "").."\",")
		end

		print("        },")
	end

	print("    },")
end

local function potentials_found()
	print("    potential = {")

	for potential in pairs(filtered_words.potential) do
		print("        [\""..potential.."\"] = {")

		for count, message in pairs(filtered_words.potential[potential]) do
			print("            \""..gsub(message, "\"", "").."\",")
		end

		print("        },")
	end

	print("    },")
end

print("return {")
	positive_matches()
	potentials_found()
print("} \n")


print(
	"line count: "..ln.."\n"..
	"word count: "..wc.."\n"..
	"black list: "..bl.."\n"..
	"filter hit: "..ps.."\n"..
	"potentials: "..pn.."\n"..
	"clock time: "..tonumber(string.format("%.6f", os.clock() - osc)).."\n"
)
