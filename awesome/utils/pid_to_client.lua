local capi = {
    client = client,
}
local log = require('logging').getLogger(...)

local M = {}

M.pid_callbacks = {}

function M.set_pid_callback(pid, callback)
    M.pid_callbacks[pid] = callback
end

function M.on_manage(c, startup)
	if startup then -- this program was not started by us
		return
	end
    if M.pid_callbacks[c.pid] ~= nil then
        local callback = M.pid_callbacks[c.pid] 
        M.pid_callbacks[c.pid] = nil
        callback(c)
        return
    end
end

capi.client.connect_signal("manage", M.on_manage)

return M