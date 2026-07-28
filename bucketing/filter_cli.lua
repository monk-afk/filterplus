local string_format = string.format
local string_rep = string.rep
local table_unpack = table.unpack or unpack

local function format_string(...)
  return string_format( string_rep("%s", #{...}),
      table_unpack({...}, 1, #{...})
    )
end


local function run_cli_filter(path)
  local bucketing_path = string.match(debug.getinfo(1, "S").source, "^@(.*[/\\])") or "./"

  local filter_path = path and path ~= ""
      and string.gsub(path, "([^/\\])$", "%1/")
      or bucketing_path .. "../"
  local filter = dofile(filter_path .. "init.lua")(filter_path)
  local buffer_controller = dofile(bucketing_path .. "buffer_controller.lua")
  local output_file_pattern = bucketing_path .. "corpus/bucket_output/messages_%s.txt"
  local buffer = buffer_controller(output_file_pattern, "clean", "dirty", "ambig")

  while true do
    local user_input = io.read()

    if not user_input then
      break
    end

    local filtered_message, bucket, candidates = filter(user_input)

    local candidate_diagnostics = {}
    for i, e in ipairs(candidates) do
      candidate_diagnostics[i] = format_string(
          "[", table.concat(e.blacklisted_words or {}, ", "),":",
          e.string_matched or "", ":",
          e.votes or "0", "/3:",
          e.confidence or "0.00", ":",
          tostring(e.triage_vote), ":",
          tostring(e.pattern_vote) ,"]"
        )
    end

    user_input = format_string( filtered_message, "\t",
      table_unpack(candidate_diagnostics, 1, #candidate_diagnostics)
    )

    buffer(bucket, user_input)
  end

  buffer()
end

local invoked = arg and arg[0] or ""
return invoked:match("filter_cli%.lua$") and run_cli_filter() or run_cli_filter
