local naughty = require('naughty')
local M = {}

function M.create_timer_and_fire(func, interval)
    func()
    local new_timer = timer({ timeout = interval })
    new_timer:connect_signal("timeout", func)
    new_timer:start()
    return new_timer
end

function M.run_after(seconds, func)
    local t = timer({timeout = seconds})
    t:connect_signal("timeout", function()
        t:stop()
        func()
    end)
    t:start()
    return t
end

function M.dbg(...)
    local printResult = ''
    local arg = {...}
    for i = 1, #arg do
        printResult = printResult .. tostring(arg[i]) .. (i == #arg and '' or ' ')
    end
    naughty.notify({text = printResult})
end

function M.monospace(text)
  return "<span face='monospace'>" .. text .. "</span>"
end

return M