local awful = require("awful")
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local utils = require('utils')
local pid_to_client = require('utils.pid_to_client')

M = {}

M.floaters = {}

M.Floater = utils.class()

function M.Floater:init(args)
    -- Client rule-properties that will be added to awful.rules
    -- Also this rule will be used to restore "lost" clients after awesome.restart()
    self.rule = args.rule
    self.properties = args.properties
    -- Command that will be launched by awful.util.spawn
    self.command = args.command
    -- Should have 4 fields - x, y, width and height.
    -- If field value is positive, it will be taken as is.
    -- If field value is negative this value will be multiplied  by the workarea height/width
    self.geometry = args.geometry
    -- Set this argument to true if your client starts slowly.
    self.keep_in_background = args.keep_in_background
    self.client = nil
end

function M.Floater:init_client()
    self.client:connect_signal("unmanage", function () self:on_unmanage() end)
    self.client:connect_signal("unfocus", function () self:on_unfocus() end)
    self:apply_client_settings()
    self:update_geometry()
end

function M.Floater:apply_client_settings()
    c = self.client
    c.skip_taskbar = true
    awful.rules.apply(c)
    awful.placement.no_overlap(c)
    awful.placement.no_offscreen(c)
    -- We want to be able to resize such windows, so, comment the next line
    -- self.client:buttons({})
    c:keys({})
    c.size_hints_honor = false
end

local function relative_to_absolute(value, absolute)
    if value >= 0 then
        return value
    end
    return (- value * absolute)
end

function M.Floater:update_geometry()
    if self.geometry == nil then
        return
    end
    local screen_geom = capi.screen[capi.mouse.screen].workarea
    local sw, sh = screen_geom.width, screen_geom.height
    local client_geometry = {}
    client_geometry.x = relative_to_absolute(self.geometry.x, sw)
    client_geometry.width = relative_to_absolute(self.geometry.width, sw)
    client_geometry.y = relative_to_absolute(self.geometry.y, sh)
    client_geometry.height = relative_to_absolute(self.geometry.height, sh)
    self.client:geometry(client_geometry)
end

function M.Floater:hideshow(show)
    if show == nil then
        show = not self.client:isvisible()
    end
    if show then -- Show the client on the current tag
        self:show()
    else -- Hide it
        self:hide()
    end
end

function M.Floater:toggle(show)
    if self:has_client() then
        self:hideshow(show)
        return
    end
    -- Spawn it and then toggle
    -- If we toggle a floater that wasn't spawned before, show it.
    if show == nil then
        show = true
    end
    self:spawn(function () 
        self:hideshow(show)
    end)
end

function M.Floater:show()
    awful.client.movetotag(awful.tag.selected(1), self.client)
    capi.client.focus = self.client
    self.client:raise()
end

function M.Floater:hide()
    self.client.hidden = true
end

function M.Floater:set_client(c)
    self.client = c
end

function M.Floater:has_client()
    return self.client ~= nil
end

function M.Floater:has_pending_client()
    return self._is_already_spawning
end

function M.Floater:client_matches(c)
    return self.rule ~= nil and awful.rules.match(c, self.rule)
end

function M.Floater:spawn_in_bg()
    if not (self:has_client() or self:has_pending_client()) then
        self:spawn(function () self:hide() end)
    end
end

function M.Floater:on_unmanage()
    self.client = nil
    if self.keep_in_background then
        utils.run_after(1, function ()
            self:spawn_in_bg()
        end)
    end
end

function M.Floater:on_unfocus()
    self:hide()
end

function M.Floater:on_added()
    if self.keep_in_background then
        utils.run_after(0, function ()
            self:spawn_in_bg()
        end)
    end
end

function M.Floater:get_rule_prop_pair()
    if self.rule == nil or self.properties == nil then
        return nil
    end
    return {
        rule = self.rule,
        properties = self.properties,
    }
end

function M.Floater:start_app()
    return awful.util.spawn(self.command)
end


function M.Floater:spawn(on_spawned_callback)
    if self:has_client() then
        if on_spawned_callback ~= nil then
            on_spawned_callback()
        end
        return
    end
    if self._is_already_spawning ~= nil then
        table.insert(self._on_spawned_callbacks, on_spawned_callback)
        return
    end
    self._is_already_spawning = true
    self._on_spawned_callbacks = {on_spawned_callback}

    local pid = self:start_app()
    pid_to_client.set_pid_callback(pid, function (c)
        self:set_client(c)
        self._is_already_spawning = nil
        callbacks = self._on_spawned_callbacks
        self._on_spawned_callbacks = nil
        utils.run_after(0, function()
            self:init_client()
            for _, callback in ipairs(callbacks) do
                callback()
            end
        end)
    end)

end

function M.on_manage(c, startup)
    if not startup then -- we will try to recover lost floaters only after awesome.restart()
        return
    end
    -- Maybe this client was a floater and was "lost" after awesome restart? If so, restore the floater.
    for floater_name, floater in pairs(M.floaters) do
        if not floater:has_client() and floater:client_matches(c) then
            floater:set_client(c)
            -- It's crucial to run init_client not in manage signal handler.
            utils.run_after(0, function()
                floater:init_client()
                -- By default we will just hide all "recovered" floaters.
                floater:hide()
            end)

            break
        end
    end
end

function M.toggle(floater_name, show)
    local floater = M.floaters[floater_name]
    floater:toggle(show)
end

function M.get_rules_properties()
    result = {}
    for floater_name, floater in pairs(M.floaters) do
        table.insert(result, floater:get_rule_prop_pair())
    end
    return result
end

function M.add(floater_name, floater)
    M.floaters[floater_name] = floater
    floater:on_added()
end

capi.client.connect_signal("manage", M.on_manage)

return M

