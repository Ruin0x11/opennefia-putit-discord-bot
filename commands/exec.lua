local ReplLayer = require("OpenNefia.src.api.gui.menu.ReplLayer")
local Repl = require("OpenNefia.src.api.Repl")
local util = require("OpenNefia.src.tools.cli.util")
local args = require("config")

local exec = {}

exec.description = "Execute Lua code using OpenNefia's runtime. Kinda unsafe."

exec.allowed_roles = { "admin" }

local function wrap_code(str)
   return ('```\n%s```'):format(str)
end

local MAX_LENGTH = 1990

local function run_code(code, env)
   local continue, status, success, result, fn
   local dt = 0

   fn, result = loadstring("return " .. code)
   if not fn then
      fn, result = loadstring(code)
   end

   if fn then
      if env then
         setfenv(fn, env)
      end

      -- NOTE: It is very important that the code being run does not
      -- call coroutine.yield, or it will mess up the flow and
      -- potentially leave the debug server in an invalid state. To
      -- protect against this, run the code itself in a new coroutine
      -- so if the code yields it will not affect any state.
      local coro = coroutine.create(function() return xpcall(fn, function(e) return e .. "\n" .. debug.traceback(2) end) end)
      repeat
         continue, success, result = coroutine.resume(coro, dt, nil)
         dt = 0
      until not continue or coroutine.status(coro) == "dead"

      if continue then
         success = true
         status = "success"
      else
         status = "exec_error"
      end
   else
      status = "compile_error"
   end

   if not success then
      return success, tostring(result)
   end

   return success, ReplLayer.format_repl_result(result)
end

local function do_exec(arg, msg)
   if not arg then return end
   if msg.author ~= msg.client.owner then return end

   arg = arg:gsub('```\n?', '') -- strip markdown codeblocks

   local lines = {}

   local exec_env = Repl.generate_env()
   rawset(exec_env, "pass_turn", util.pass_turn)
   rawset(exec_env, "load_game", util.load_game)

   local print_handler = function(...)
      for i = 1, select("#", ...) do
         table.insert(lines, tostring(select(i, ...)))
      end
   end

   rawset(exec_env, "print", print_handler)
   args.set_print_handler(print_handler)

   local success, out = run_code(arg, exec_env)
   args.set_print_handler(nil)

   if not success then return msg:reply(wrap_code(out)) end

   lines[#lines+1] = out

   lines = table.concat(lines, '\n')

   if #lines > MAX_LENGTH then -- truncate long messages
      lines = lines:sub(1, MAX_LENGTH-6) .. " <...>"
   end

   return msg:reply(wrap_code(lines))
end

local function parse_rest(content)
   return content:sub(7)
end

function exec.exec(message)
   local arg = parse_rest(message.content)
   return do_exec(arg, message)
end

return exec
