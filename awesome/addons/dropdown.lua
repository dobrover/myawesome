local awful = require("awful")
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local utils = require('utils')

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
    -- If field value is negative this value will be multiplied  by the workarea height/width.
    self.geometry = args.geometry
    -- Set this argument to true if your client starts slowly.
    self.keep_in_background = args.keep_in_background
    self.client = nil
end

--- Make client belong to a floater, set properties, etc. Called only once.
function M.Floater:init_client()
    self.client:connect_signal("unmanage", function () self:on_unmanage() end)
    self.client:connect_signal("unfocus", function () self:on_unfocus() end)
    self:apply_client_settings()
    self:update_geometry()
end

--- Same as init_client but ran in 'manage' signal handler
function M.Floater:init_client_direct()
end

--- Make client a special window.
function M.Floater:apply_client_settings()
    c = self.client
    c.skip_taskbar = true
    awful.placement.no_overlap(c)
    awful.placement.no_offscreen(c)
    -- We want to be able to resize such windows, so, comment the next line
    -- self.client:buttons({})
    c:keys({})
    c.size_hints_honor = false
    if self.rules == nil then
        -- Client didn't provide us with rules to detect the client so apply properties manually
        -- This will cause the layout to blink if for example the current layout is tiling
        -- and we want to set floating=true
        if self.properties then
            local entry = {properties = self.properties}
            utils.rules.apply_to_client(c, {entry})
        end
    end 
end

--- Helper function for update_geometry.
local function relative_to_absolute(value, absolute)
    if value >= 0 then
        return value
    end
    return (- value * absolute)
end

--- Updates client position and size.
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

--- Shows or hides client depending on `show` param.
-- @param show Whether client should be shown or hidden. If this
--             value is nil, the client's visibility is toggled.
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

--- Tries to hide/show a floater's client, if there is no client, spawns it.
-- @param show Same as in Floater:hideshow.
function M.Floater:toggle(show)
    if self:has_client() then
        self:hideshow(show)
        return
    end
    -- Spawn it and then toggle.
    -- If we toggle a floater that wasn't spawned before, show it.
    if show == nil then
        show = true
    end
    self:spawn(function () self:hideshow(show) end)
end

--- Shows client.
function M.Floater:show()
    awful.client.movetotag(awful.tag.selected(1), self.client)
    capi.client.focus = self.client
    self.client:raise()
end

--- Hides client.
function M.Floater:hide()
    self.client.hidden = true
end

--- Sets floater's client.
function M.Floater:set_client(c)
    self.client = c
end

--- Tells if this floater has a client.
function M.Floater:has_client()
    return self.client ~= nil
end

--- Tells if there is a client being spawned.
function M.Floater:has_pending_client()
    return self._is_already_spawning
end

--- Tells if this client can belong to this floater.
function M.Floater:client_matches(c)
    return self.rule ~= nil and awful.rules.match(c, self.rule)
end

--- Spawns a client in the background if it is not yet spawned and if it is not being spawned.
function M.Floater:spawn_in_bg()
    if not (self:has_client() or self:has_pending_client()) then
        self:spawn(nil, function () self:hide() end)
    end
end

--- Called when client window was closed, try to reopen it in background if option is set.
function M.Floater:on_unmanage()
    self.client = nil
    if self.keep_in_background then
        utils.run_after(1, function ()
            self:spawn_in_bg()
        end)
    end
end

--- Called when client loses focus
function M.Floater:on_unfocus()
    self:hide()
end

--- Called when floater is added to floaters table
function M.Floater:on_added()
    if self.keep_in_background then
        utils.run_after(0, function ()
            self:spawn_in_bg()
        end)
    end
end

--- Return floater's rule/properties so that it can be added to awful.rules.rules
function M.Floater:get_rule_prop_pair()
    if self.rule == nil or self.properties == nil then
        return nil
    end
    return {
        rule = self.rule,
        properties = self.properties,
    }
end

--- Starts floater's client. Must return pid.
function M.Floater:start_app()
    result = awful.util.spawn(self.command)
    return result
end

--- Spawns a client. If multiple spawns were issued before client was managed,
--- their callbacks will be ordered in queue.
-- @param indirect_callback Callback to be spawned after client in spawned, but not in the
--                          manage handler. This is required when current tag layout is floating.
-- @param callback Callback to be called after client is spawned.
function M.Floater:spawn(indirect_callback, callback)
    if self:has_client() then
        -- It is probably a bug if we got here.
        return
    end
    self._spawn_callbacks = self._spawn_callbacks or {}
    self._indirect_spawn_callbacks = self._indirect_spawn_callbacks or {}
    table.insert(self._spawn_callbacks, callback)
    table.insert(self._indirect_spawn_callbacks, indirect_callback)
    if self._is_already_spawning then
        return
    end
    self._is_already_spawning = true

    local pid = self:start_app()
    utils.pid_to_client.set_pid_callback(pid, function (c)
        self:set_client(c)
        self._is_already_spawning = false
        callbacks = self._spawn_callbacks
        indirect_callbacks = self._indirect_spawn_callbacks
        self._spawn_callbacks = nil
        self._indirect_spawn_callbacks = nil
        utils.run_after(0, function()
            self:init_client()
            for _, cb in ipairs(indirect_callbacks) do
                cb()
            end
        end)
        self:init_client_direct()
        for _, cb in ipairs(callbacks) do
            cb()
        end
    end)

end

--- Called when a new client appears
function M.on_manage(c, startup)
    if not startup then -- we will try to recover lost floaters only after awesome.restart()
        return
    end
    -- Maybe this client was a floater and was "lost" after awesome restart? If so, restore the floater.
    for floater_name, floater in pairs(M.floaters) do
        if not floater:has_client() and floater:client_matches(c) then
            floater:set_client(c)
            -- It's crucial to run init_client not in manage signal handler.
            -- Because for example c:geometry call is done there.
            -- If c:geometry call is done in manage signal handler directly
            -- and the client has just spawned and the current layout is floating
            -- then the geometry call won't set client position/size.
            utils.run_after(0, function()
                floater:init_client()
                -- By default we will just hide all "recovered" floaters.
                floater:hide()
            end)

            break
        end
    end
end

--- Toggles floater `floater_name`.
function M.toggle(floater_name, show)
    local floater = M.floaters[floater_name]
    floater:toggle(show)
end

--- Returns table of rules of all floaters.
function M.get_rules_properties()
    result = {}
    for floater_name, floater in pairs(M.floaters) do
        table.insert(result, floater:get_rule_prop_pair())
    end
    return result
end

--- Add Floater object and name it as `floater_name`
function M.add(floater_name, floater)
    M.floaters[floater_name] = floater
    floater:on_added()
end

capi.client.connect_signal("manage", M.on_manage)

return M

