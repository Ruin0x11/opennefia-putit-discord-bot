local commands = {
   "info",
   "exec",
   "reset",
}

local function require_command(name)
   return name, require(("commands.%s"):format(name))
end

return fun.iter(commands):map(require_command):to_map()
