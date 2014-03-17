local apprules = {}

local awful = require 'awful'
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local utils = require 'utils'
local log = (require'logging').getLogger(...)

local apprules_storage = rc.get_storage('apprules.applied_rules')

local launched_rules

-- Rules that will be executed always.
apprules.permanent_rules = {}

apprules.onetimerules = {
    firefox = { rule = { class = "Firefox" },
      properties = { tag = rc.tags[1][1] } },
    pidgin_converation = { rule = { class = "Pidgin", role = "conversation" },
      properties = { tag = rc.tags[1][2] } },
    pidgin_buddy_list = { rule = { class = "Pidgin", role = "buddy_list"},
      properties = { tag = rc.tags[1][7] } },
    deadbeef = { rule = { class = "Deadbeef" },
      properties = { tag = rc.tags[1][5] } },
    weechat = { rule = { class = "URxvt", name = "weechat" },
      properties = { tag = rc.tags[1][4] } },      
}


function apprules.on_manage(c, startup)
    -- If this behaves strangely, replace with memstorage.
    if startup then
        return
    end
    for rulename, ruleprop in pairs(apprules.onetimerules) do
        if apprules_storage:get(rulename) then
            apprules.onetimerules[rulename] = nil
        elseif awful.rules.match(c, ruleprop.rule) then
            log:debug("Matched! %s", c.name)
            utils.run_after(0, function ()
                utils.rules.apply_to_client(c, {ruleprop})
            end)
            apprules_storage:set(rulename, true)
            apprules.onetimerules[rulename] = nil
            break
        end
    end        
end

capi.client.connect_signal("manage", apprules.on_manage)

return apprules
