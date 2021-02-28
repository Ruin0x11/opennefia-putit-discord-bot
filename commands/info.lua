local info = {}

info.description = "Test command."

function info.exec(message)
   message.channel:send("dood")
end

return info
