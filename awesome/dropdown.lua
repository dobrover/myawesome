-- Example usage:
--
-- dropdown = require('dropdown')
-- local urxvt_title = "dropdownURxvt"
-- dropdown.floaters["urxvt"] = {
--     -- Rule by which your client will be identified after awesome restart.
--     -- Usually clients are identified by their pids.
--     rule = {
--       class = "URxvt",
--       name = urxvt_title
--     },
--     -- Disable tabs because of bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=511377
--     command = ("urxvt --title '%s' -pe '-tabbedex,-tabbed' "):format(urxvt_title),
--     -- If negative, value will be taken as is. Otherwise it will be multiplied by workarea size.
--     geometry = {x = 0.10, y = -20, width = 0.8, height = 0.5},
--     
-- }
--
-- Then use dropdown.toggle("urxvt") when you want to spawn/despawn the client
--
-- It's also recommended to add the following to your rules to avoid blinking on tiling layouts.
--
-- { rule = dropdown.floaters["urxvt"].rule,
--       properties = { floating = true } },


local awful = require("awful")
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
-- Is there a better name for this module?
local utils = require('utils')


M = {}

-- This allows calling callbacks on clients after awful.util.spawn
M.pid_callbacks = {}
M.floaters = {}

function M.add_pid_callback(pid, callback)
    M.pid_callbacks[pid] = callback
end


function M.on_manage(c)
    if M.pid_callbacks[c.pid] ~= nil then
        local cb = M.pid_callbacks[c.pid] 
        M.pid_callbacks[c.pid] = nil
        cb(c)
        return
    end

    -- Maybe this client was a floater and was "lost" after awesome restart? If so, restore the floater.
    local lost_floater_name = nil

    for floater_name, floater in pairs(M.floaters) do
        if floater.client == nil and floater.rule ~= nil then
            if awful.rules.match(c, floater.rule) then
                floater.client = c
                lost_floater_name = floater_name
                break
            end
        end
    end

    if lost_floater_name == nil then
        return
    end

    local floater = M.floaters[lost_floater_name]

    -- update client properties and make it floating
    utils.run_after(0, function()
        M.on_created(floater, true)
    end)
end

local function spawn_floater(floater)
    local pid = awful.util.spawn(floater.command)
    -- Put this in another function
    M.add_pid_callback(pid, function (c)
        floater.client = c
        utils.run_after(0, function()
            M.on_created(floater)
            M.on_toggled(floater, true)
        end)
    end)
end

function M.toggle(floater_name)
    floater = M.floaters[floater_name]
    if floater.client == nil then
        spawn_floater(floater)
    else
        M.on_toggled(floater, false)
    end
end

function M.on_floater_unmanaged(floater)
    floater.client = nil
end

function M.on_floater_unfocus(floater)
    floater.client.hidden = true
end

function M.on_created(floater, hide)
    floater.client:connect_signal("unmanage", function () M.on_floater_unmanaged(floater) end)
    floater.client:connect_signal("unfocus", function () M.on_floater_unfocus(floater) end)
    floater.client.skip_taskbar = true
    -- XXX: do we really need this? Maybe always set floating through rules?
    awful.client.floating.set(floater.client, true)
    awful.placement.no_overlap(floater.client)
    awful.placement.no_offscreen(floater.client)
    -- This is not a normal window, don't apply any specific keyboard stuff
    -- floater.client:buttons({})
    floater.client:keys({})
    -- floater.client.border_width = 0
    floater.client.size_hints_honor = false
    local geom = M.update_geometry(floater)
    floater.client:geometry(geom)
    if hide then
        floater.client.hidden = true
    end

end

-- created = true if windows was just created
function M.on_toggled(floater, created)
    if not floater.client:isvisible() or created then -- Show the client on the current tag
        awful.client.movetotag(awful.tag.selected(1), floater.client)
        capi.client.focus = floater.client
        floater.client:raise()
    else -- Hide it
        floater.client.hidden = true
    end
end

function M.update_geometry(floater)
    local x, y, width, height
    x = floater.geometry.x
    y = floater.geometry.y
    width = floater.geometry.width
    height = floater.geometry.height
    local geom = capi.screen[capi.mouse.screen].workarea
    x = x < 0 and -x or geom.width * x
    y = y < 0 and -y or geom.height * y
    width = width < 0 and -width or geom.width * width
    height = height < 0 and -height or geom.height * height
    return {x = x, y = y, width = width, height = height}

end

function M.get_rules_properties()
    result = {}
    for floater_name, floater in pairs(M.floaters) do
        if floater.rule ~= nil and floater.properties ~= nil then
            table.insert(result, {
                rule = floater.rule,
                properties = floater.properties
            })
        end
    end
    return result
end

capi.client.connect_signal("manage", M.on_manage)

return M

