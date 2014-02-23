local utils = require('utils')
local M = {}

M.widget = wibox.widget.textbox()

function M.set_markup(markup)
	M.widget:set_markup( utils.monospace(markup) .. '|')
end

M.set_markup("US")

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", 
	function(interface, type, bus, member, path)
	    local layout = type
	    lts = {[0] = "US", [1] = "RU"}
	    M.set_markup(lts[layout])
    end
)

return M