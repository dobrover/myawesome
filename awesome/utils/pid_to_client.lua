local pid_to_client = {}

local capi = {
    client = client,
}
local awful = require 'awful'
local utils = require 'utils'
local log = require('logging').getLogger(...)

pid_to_client.pid_callbacks = {}

function pid_to_client.set_pid_callback(pid, callback, early_callback)
    pid_to_client.pid_callbacks[pid] = {
        callback = callback,
        early_callback = early_callback
    }
end

function pid_to_client.on_early_manage(c, startup)
	if startup then -- this program was not started by us
		return
	end
    if pid_to_client.pid_callbacks[c.pid] ~= nil then
        local callbacks = pid_to_client.pid_callbacks[c.pid] 
        if callbacks.early_callback then
            callbacks.early_callback(c)
        end
    end
end

function pid_to_client.on_manage(c, startup)
    if startup then -- this program was not started by us
        return
    end
    if pid_to_client.pid_callbacks[c.pid] ~= nil then
        local callbacks = pid_to_client.pid_callbacks[c.pid]
        pid_to_client.pid_callbacks[c.pid] = nil
        if callbacks.callback then
            callbacks.callback(c)
        end 
        return
    end
end

function pid_to_client.setup()
    if not pid_to_client._setup then
        pid_to_client._setup = true
        utils.early_manage.setup()
        capi.client.connect_signal("early_manage", pid_to_client.on_early_manage)
        capi.client.connect_signal("manage", pid_to_client.on_manage)
    end
end

return pid_to_client
