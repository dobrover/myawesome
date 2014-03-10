-- Module for miscelaneous stuff that doesn't deserve its own module.

local M = {}
local log = require('logging').getLogger(...)

local naughty = require('naughty')
M.eye_relax_timer = timer({timeout = 60*10})
M.eye_relax_timer:connect_signal('timeout', function ()
	naughty.notify({
		text = "Time to look somewhere else!",
		timeout = 30,
		ontop = true,
		run = function ()
			naughty.notify({text = "No, you must do this!", timeout = 15, ontop = true})
		end
	})
end)
M.eye_relax_timer:start()

return M