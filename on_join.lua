return function(filter)
  core.register_on_prejoinplayer(
    function(preferred_name, ip)
      -- if name is censored, it won't match the player's chosen name
      local filtered_name = filter(preferred_name) == preferred_name

      if not filtered_name then
        core.log("action", "Player attempted to connect with a censored name: " .. preferred_name)
        return "Server detected inappropriate username. If you believe this is an error, please notify the admin."
      end
    end
  )
end
