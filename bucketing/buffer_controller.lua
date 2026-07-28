-- buffer_controller.lua
local function buffer_controller(output_file_pattern, ...)
  local buffer_max = 25000
  local output_buffer = {}

  for _, key in pairs({...}) do
    output_buffer[key] =  {
      pos = 0, msgs = {}
    }
  end

  local output_files = {}

  for bucket, _ in pairs(output_buffer) do
    if not output_files[bucket] then
      output_files[bucket] = string.format(output_file_pattern, bucket)
    end
  end

  local open_files = {}

  for bucket, file_out in pairs(output_files) do
    local output_file, open_error = io.open(file_out, "w")
    assert(output_file, ("%s: %s"):format(file_out, open_error or "unable to open"))
    open_files[bucket] = output_file
  end

  local table_concat = table.concat

  return function(bucket, message)
    if message and bucket then
      local ob = output_buffer[bucket]
      ob.pos = ob.pos + 1

      ob.msgs[ob.pos] = message

      if ob.pos >= buffer_max then
        local output_file = open_files[bucket]
        output_file:write(table_concat(ob.msgs, "\n"), "\n")

        ob.msgs = {}
        ob.pos = 0
      end
    else
      -- close all files after dumping them
      for bkt, c in pairs(output_buffer) do
        local output_file = open_files[bkt]
        if #c.msgs > 0 then
          output_file:write(table_concat(c.msgs, "\n"), "\n")
        end
        output_file:close()
      end
    end
  end
end

return buffer_controller
