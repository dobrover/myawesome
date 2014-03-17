local early_manage = {}

-- Module that adds "early_manage" signal that is executed 
-- before default awesome "manage" signal handler (which is awful.rules.apply)
-- Usage: put require('early_manage').setup() at the top of rc.lua
-- And then just use "early_manage" signal as you wish.

local capi = {
    client = client,
}
local awful = require 'awful'

-- Uncomment if you have https://github.com/dobrover/logging
-- local log = (require 'logging').getLogger(...)

function early_manage.on_before_manage(...)
    -- Relies on the fact that emit_signal simply calls every signal handler
    -- in the current event handler.
    capi.client.emit_signal("early_manage", ...)
end

function early_manage.setup()
    if not early_manage._setup then
        early_manage._setup = true
        capi.client.add_signal("early_manage")
        capi.client.disconnect_signal("manage", awful.rules.apply)
        capi.client.connect_signal("manage", early_manage.on_before_manage)
        capi.client.connect_signal("manage", awful.rules.apply)
    end
end

return early_manage
