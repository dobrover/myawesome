local kbdd = {}
local utils = require('utils')
local log = require('logging').getLogger(...)

kbdd.widget = wibox.widget.textbox()

function kbdd.set_markup(markup)
	kbdd.widget:set_markup( utils.monospace(markup) .. '|')
end

kbdd.set_markup("US")

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", 
	function(interface, type, bus, member, path)
	    local layout = type
	    lts = {[0] = "US", [1] = "RU"}
	    kbdd.set_markup(lts[layout])
    end
)

return kbdd