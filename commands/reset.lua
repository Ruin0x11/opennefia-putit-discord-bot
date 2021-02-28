local field = require("OpenNefia.src.game.field")
local field_logic = require("OpenNefia.src.game.field_logic")
local args = require("config")

local reset = {}

reset.description = "Resets the global state of the headless environment."

function reset.exec(message)
   field:init_global_data()
   if args.quickstart_on_startup then
      field_logic.quickstart()
   end
   return message:reply("Reset all global state.")
end

return reset
