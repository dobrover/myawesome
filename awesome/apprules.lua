local apprules = {}

local awful = require 'awful'
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local utils = require 'utils'
local log = (require'logging').getLogger(...)

-- Rules that will be executed always.
apprules.permanent_rules = {}

apprules.onetimerules = {
    { rule = { class = "Firefox" },
      properties = { tag = rc.tags[1][1] } },
    { rule = { class = "Pidgin", role = "conversation" },
      properties = { tag = rc.tags[1][2] } },
    { rule = { class = "Pidgin", role = "buddy_list"},
      properties = { tag = rc.tags[1][7] } },
    { rule = { class = "Deadbeef" },
      properties = { tag = rc.tags[1][5] } },
    { rule = { class = "URxvt", name = "weechat" },
      properties = { tag = rc.tags[1][4] } },      
}

function apprules.on_manage(c, startup)
    -- If this behaves strangely, replace with memstorage.
    if startup then
        return
    end
    for i, ruleprop in ipairs(apprules.onetimerules) do
        if awful.rules.match(c, ruleprop.rule) then
            log:debug("Matched! %s", c.name)
            utils.run_after(0, function ()
                utils.rules.apply_to_client(c, {ruleprop})
            end)
            table.remove(apprules.onetimerules, i)
            break
        end
    end        
end

capi.client.connect_signal("manage", apprules.on_manage)

return apprules
