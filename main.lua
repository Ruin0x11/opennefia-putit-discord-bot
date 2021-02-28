local print_ = print
local args = require("config")
args.print_handler = print_
function args.set_print_handler(h)
   args.print_handler = h or print_
end

package.path = package.path .. ";./OpenNefia/src/?.lua;./OpenNefia/src/?/init.lua"
require("boot")
-- rawset(_G, "require", require_)

local _G_mt = getmetatable(_G)
_G_mt.__declared["arg"] = true
rawset(_G, "print", function(...) args.print_handler(...) end)

local function to_open_nefia_search_path(search_path)
   if search_path:match("^/") or search_path:match("^%./OpenNefia/src") then
      return search_path
   end

   return search_path:gsub("^%./", "./OpenNefia/src/")
end

local search_paths = fun.iter(string.split(package.path, ";")):map(to_open_nefia_search_path):to_list()
search_paths[#search_paths+1] = "./?.lua"
search_paths[#search_paths+1] = "./?/init.lua"
package.path = table.concat(search_paths, ";")

-- --------------------------------------------------------------------------------

require("OpenNefia.src.internal.data.base")
local fs = require("util.fs")
local mod = require("OpenNefia.src.internal.mod")
local startup = require("OpenNefia.src.game.startup")
local field = require("OpenNefia.src.game.field")
local field_logic = require("OpenNefia.src.game.field_logic")
local Event = require("OpenNefia.src.api.Event")

fs.set_global_working_directory("OpenNefia/src")

local function setup()
   if not fs.exists(fs.get_save_directory()) then
      fs.create_directory(fs.get_save_directory())
   end

   local enabled_mods
   if args.load_all_mods then
      enabled_mods = nil
   else
      enabled_mods = args.enabled_mods or { "base", "elona_sys", "elona", "extlibs" }
   end
   local mods = mod.scan_mod_dir(enabled_mods)
   startup.run_all(mods)

   Event.trigger("base.on_startup")
   field:init_global_data()
   if args.quickstart_on_startup then
      field_logic.quickstart()
   end
end

setup()

local discordia = require("discordia")
local client = discordia.Client()

local PREFIX = "!"
local commands = require("commands")

local DISCORD_BOT_TOKEN = require("secret").token

local function can_execute(member, command)
   if command.allowed_roles then
      for _, allowed_role in ipairs(command.allowed_roles) do
         for _, role in pairs(member.roles) do
            if role.name:lower() == allowed_role:lower() then
               return true
            end
         end
      end

      return false, ("Allowed roles: %s"):format(table.concat(command.allowed_roles, " "))
   end

   return true
end

local callbacks = {}

function callbacks.ready()
   print(("logged in as %s"):format(client.user.username))
end

function callbacks.messageCreate(message)
   if message.author.bot then return end

   if not message.content:sub(1, 1) == PREFIX then
      return
   end

   local msg_args = message.content:split(" ") -- split all arguments into a table
   if #msg_args == 0 then
      return
   end

   msg_args[1] = msg_args[1]:sub(2)

   client:info("Received command %s - %s", msg_args[1], message.content)

   local command = commands[msg_args[1]]
   if command then
      local ok, err = can_execute(message.member, command)
      if not ok then
         message:reply(("You don't have permission to do that. %s"):format(err))
         return
      end

      command.exec(message)
   elseif msg_args[1] == "help" then -- display all the commands
      local output = {}
      for word, tbl in pairs(commands) do
         table.insert(output, "Command: " .. word .. "\nDescription: " .. tbl.description)
      end

      message:reply(table.concat(output, "\n\n"))
   end
end

for name, cb in pairs(callbacks) do
   client:on(name, cb)
end

client:run(("Bot %s"):format(DISCORD_BOT_TOKEN))
