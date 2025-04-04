       ----------------------
  --==[[  CLIP © 2025 monk  ]]==--
       ----------------------

--[[ README -------------------------------------------------

Extracts and handles command line arguments (arg)

Argument handling:
  - String and numeric assignments as their respective values
  - Standalone arguments (e.g., arg2 and -a) as booleans

Sets clip[0] to the running script's file name and clip[file] to its path.
  - If the pwd is the current directory, clip[file] fill be empty (not nil)
  - Otherwise, the value of clip[file] will be the full path

Keeps positional arguments as a numeric array and associate keywords with values,
  providing access to both sequential and associative data.

Example:

  $ lua ${PWD}/clip.lua --arg1="the long string" arg2 num=9 -a 889

The table produced:

  clip = {
    "arg1", "arg2", "num", "a", "889", -- numeric array first
    [0] = "clip.lua",                  -- clip[0] is the file name
    ["clip.lua"] = "/home/user/clip/", -- clip[file] gives the path
    arg1 = "the long string",          -- strings stay strings
    arg2 = true, a = true,             -- standalone args become boolean
    num = 9,                           -- numbers stay numbers if associated
    ["889"] = true                     -- standalone numbers become boolean
  }

The table can then be assigned additional keys and values during runtime; clip.new_key = "val", 

]]
-- END OF README


-- clip.lua -----------------------------------------------
-- #!/usr/bin/lua -- can be added to $PATH to call required("clip")
local clip = {}
  -- Assign the file name and path
clip[0] = string.gsub(arg[0], "^([%w/]-/?)([%w%.]+)$",
    function(path, file)
      clip[file] = path
      return file, path
    end)
  -- Evaluate argumets after the file
for p = 1, #arg do
  clip[p] = string.gsub(arg[p], "%-*([%w-]+)=?([%s%S]*)",
    function(param, val)
      clip[param] = val == "" or tonumber(val) or val
      return param, val
    end)
end

return clip
-- END OF clip.lua


-- Usage Examples -----------------------------------------------
--[[ remove this opening multi-line comment,
    -- comment the return statement above this line, then run with:
     --   $ lua ${PWD}/clip.lua --arg1="the long string" arg2 num=9 -a 889

  print("-- Filename and Path (if included)")
    local filename = clip[0]
    local path = clip[filename]
    print(filename, path)

  print("-- Associated keys, such as --param=value or --hyphen-param (without value)")
    local value = clip.param or clip["hyphen-param"]

    for k, v in pairs(clip) do
      local param = k
      local value = v
      print(param, value)
    end

  -- Insert numeric key
    table.insert(clip, "table.insert New Value")
    clip[#clip + 1] = "Increment New Value"

  -- Create new key-value assignment
    clip.new_key = "New value"

  print("-- Positional arguments (ipairs):")
    local value = clip[1]

    for i,v in ipairs(clip) do
      local index = i
      local value = v
      print(index, value)
    end

  print("-- Positional arguments (numeric traversal):")
    for i = 1, #clip do
      local value = clip[i]
      print(value)
    end

  print("-- Concatenated array, filename omitted:")
    local conc = table.concat(clip, ", ")
    print(conc)

-- ]]


--==[[================================================================================]]==--
--==[[ MIT License                                                                    ]]==--
--==[[                                                                                ]]==--
--==[[ Copyright © 2025  monk                                                         ]]==--
--==[[                                                                                ]]==--
--==[[ Permission is hereby granted, free of charge, to any person obtaining a copy   ]]==--
--==[[ of this software and associated documentation files (the "Software"), to deal  ]]==--
--==[[ in the Software without restriction, including without limitation the rights   ]]==--
--==[[ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      ]]==--
--==[[ copies of the Software, and to permit persons to whom the Software is          ]]==--
--==[[ furnished to do so, subject to the following conditions:                       ]]==--
--==[[                                                                                ]]==--
--==[[ The above copyright notice and this permission notice shall be included in all ]]==--
--==[[ copies or substantial portions of the Software.                                ]]==--
--==[[                                                                                ]]==--
--==[[ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     ]]==--
--==[[ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       ]]==--
--==[[ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    ]]==--
--==[[ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         ]]==--
--==[[ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  ]]==--
--==[[ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  ]]==--
--==[[ SOFTWARE.                                                                      ]]==--
--==[[================================================================================]]==--