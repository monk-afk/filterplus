-- run this from command line, or pipe in from stdout
local path = os.getenv("PWD") .. "/"
local logger = print

local filter = dofile(path .. "init.lua")(path, logger)

while true do
  io.write(" > ")
  local user_input = io.read()
  if not user_input or user_input == ";q" then
    break
  else
    io.write(filter(user_input), "\n")
  end
end
