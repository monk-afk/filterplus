  -- Chat Filter - init.lua
  --	0.01 - by: monk
  --
local osc = os.clock()
local l, w, c = 0, 0, 0

local match = string.match
local gmatch = string.gmatch
local lower = string.lower
local gsub = string.gsub

local curses = dofile("./blacklist.lua")
local reference_table = {}


local index_references = function(curses)
	for i, curse in pairs(curses) do
		local head = match(curses[i], "^%S")
		local tail = match(curses[i], "%S$")

		if not reference_table[tail] then
			reference_table[tail] = {}
		end

		if not reference_table[tail][head] then
			reference_table[tail][head] = {}
		end

		table.insert(reference_table[tail][head], curse)
	end
	return reference_table
end
index_references(curses)


local evaluate = function(head, word)
	for _,curse in pairs(head) do
		if #curse == #word then
			if curse == word then
				c = c + 1
			end
		end
	end
end

local reference = function(string)
	for word in string:gmatch("%S+") do
	w = w + 1
	
		if #word > 1 then
			local tail = match(word, "%S$")

			if reference_table[tail] then
				local head = match(word, "^%S")
				head = reference_table[tail][head]
			
				if head then
					return evaluate(head, word)
				end
			end
		end
	end
end


local sweep = function(string)
	return reference(
		lower(string):
			gsub("(%w+)", " %1 "): -- extra spaces
			gsub("^%s*(.-)%s*$","%1"): -- padding
			gsub("[^%sa-zA-Z]", ""): -- non-alpha
			gsub("%s-(%w*)%s(%w)%s", "%1%2"): -- w o r d g a p s 
			gsub("([%s%S])%1([%s%S]*)%2([%s%S]*)%3", "%1"): -- reppittittionns
			gsub("([%s%S])%1", "%1") -- repititions second pass
	)
end


local function iterate_logs()
	local logfile = "./small_logfile.txt" -- 1.8MB, 100 thousand lines
	-- local logfile = "./large_logfile.txt" -- 52MB, 3 million lines

	local function file_exists(file)
		local f = io.open(file,"rb")
		if f then f:close() end
		return f~=nil
	end

	if not file_exists(logfile) then
		return
	end

	for line in io.lines(logfile) do
		l = l + 1
		sweep(line)
	end
end

iterate_logs()
	print(
		"lines: "..l.."\n"..
		"words: "..w.."\n"..
		"curse: "..c.."\n"..
		"clock: "..tonumber(string.format("%.6f", os.clock() - osc)).."\n"
	)