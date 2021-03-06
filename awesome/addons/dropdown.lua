local M = {}

local awful = require("awful")
local capi = {
    mouse = mouse,
    client = client,
    screen = screen
}
local utils = require('utils')
local common = require('common')
local logging = require('logging')
local log = logging.getLogger(...)
local oo = require('loop.simple')

M.floaters = {}

M.wid_storage = rc.get_storage('dropdown.clientid')

-- TODO: Temporary
local PrefixedLoggerAdapter = common.baseclass.class({}, logging.LoggerAdapter)
function PrefixedLoggerAdapter:process(args)
    oo.superclass(PrefixedLoggerAdapter).process(self, args)
     args[1] = self.extra.msg_prefix .. args[1]
end

M.Floater = common.baseclass.class()

function M.Floater:__create(args)
    -- Name, used for logging and to interact with specific floater.
    self.name = args.name
    -- Prefix all log messages with floater name.
    self.log = PrefixedLoggerAdapter(log, {msg_prefix=self.name .. ': '})
    -- This rule will be used for catching client if detect_by_rules = true
    self.rule = args.rule
    -- Client properties
    self.properties = args.properties
    -- Command that will be launched by awful.util.spawn
    self.command = args.command
    -- Should have 4 fields - x, y, width and height.
    -- If field value is positive, it will be taken as is.
    -- If field value is negative this value will be multiplied  by the workarea height/width.
    self.geometry = args.geometry
    -- Set this argument to true if your client starts slowly.
    self.keep_in_background = args.keep_in_background
    -- Detection by rules, useful for programs that do fork tricks.
    self.detect_by_rules = args.detect_by_rules
    self.client = nil
end

-- Initialization ran before default 'manage' signal handler.
function M.Floater:init_client_early()
    if self.properties.floating ~= nil then
        awful.client.floating.set(self.client, self.properties.floating)
    end
end

--- Initialization ran in 'manage' signal handler.
function M.Floater:init_client_direct()
    M.wid_storage:set(self.name, self.client.window)
end

--- Initialization ran in another event handler after 'manage' signal handler.
function M.Floater:init_client()
    self.client:connect_signal("unmanage", function () self:on_unmanage() end)
    self.client:connect_signal("unfocus", function () self:on_unfocus() end)
    self:apply_client_settings()
    self:update_geometry()
end

--- Make client a special window.
function M.Floater:apply_client_settings()
    c = self.client
    c.skip_taskbar = true
    awful.placement.no_overlap(c)
    awful.placement.no_offscreen(c)
    -- It turned out that we don't need to disable neither buttons nor keys.
    -- c:buttons({})
    -- c:keys({})
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
    log:debug("Toggling client to " .. (show and "visible" or "hidden"))
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
        self.log:debug("Spawning in background")
        self:spawn(nil, function () self:hide() end)
    end
end

--- Called when client window was closed, try to reopen it in background if option is set.
function M.Floater:on_unmanage()
    self.log:debug("Unmanaged" .. (self.keep_in_background and ' (will relaunch)' or '') )
    M.wid_storage:set(self.name, nil)
    self.client = nil
    if self.keep_in_background then
        utils.run_after(1, function ()
            self:spawn_in_bg()
        end)
    end
end

--- Called when client loses focus
function M.Floater:on_unfocus()
    self.log:debug("Lost focus")
    self:hide()
end

--- Called when floater is added to floaters table
function M.Floater:on_added()
    self.log:debug("Floater was added to floaters table")
    if self.keep_in_background then
        utils.run_after(0, function ()
            self:spawn_in_bg()
        end)
    end
end

--- Starts floater's client. Must return pid.
function M.Floater:start_app()
    result = awful.util.spawn(self.command)
    self.log:debug("Started app, pid: %d", result)
    return result
end

--- Spawns a client. If multiple spawns were issued before client was managed,
--- their callbacks will be ordered in queue.
-- @param indirect_callback Callback to be spawned after client in spawned, but not in the
--                          manage handler. This is required when current tag layout is floating.
-- @param callback Callback to be called after client is spawned.
-- @param early_callback Callback to be called before default "manage" signal
--                       handler (awful.rules.apply).
function M.Floater:spawn(indirect_callback, callback, early_callback)
    self.log:debug("Trying to spawn")
    if self:has_client() then
        self.log:error("Spawn was called while client was still alive.")
        return
    end
    self._spawn_callbacks = self._spawn_callbacks or {}
    self._indirect_spawn_callbacks = self._indirect_spawn_callbacks or {}
    self._early_spawn_callbacks = self._early_spawn_callbacks or {}
    table.insert(self._spawn_callbacks, callback)
    table.insert(self._indirect_spawn_callbacks, indirect_callback)
    table.insert(self._early_spawn_callbacks, early_callback)

    if self._is_already_spawning then
        self.log:warn("Can't spawn, the client is already spawning.")
        return
    end
    self._is_already_spawning = true

    local pid = self:start_app()

    local function on_spawned_cb(c) self:_on_client_spawned(c) end
    local function on_early_spawned_cb(c) self:_on_early_client_spawned(c) end

    -- TODO: This will perfectly be replaced by deferreds.
    if self.detect_by_rules then
        M._set_rule_callback(self, on_spawned_cb, on_early_spawned_cb)
    else
        self.log:debug("Setting pid callback for pid %d", pid)
        utils.pid_to_client.set_pid_callback(pid, on_spawned_cb, on_early_spawned_cb)
    end
end

function M.Floater:_on_early_client_spawned(c)
    self.log:debug("Early stage - a client was spawned!")
    self:set_client(c)
    self:init_client_early()
    local early_callbacks = self._early_spawn_callbacks
    self._early_spawn_callbacks = nil
    for _, cb in ipairs(early_callbacks) do
        cb()
    end
end

function M.Floater:_on_client_spawned(c)
    self.log:debug("A client was spawned!")
    local callbacks = self._spawn_callbacks
    local indirect_callbacks = self._indirect_spawn_callbacks
    self._spawn_callbacks = nil
    self._indirect_spawn_callbacks = nil
    self._is_already_spawning = false
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
end

-- Returns a floater that may adopt this client since it has no client
-- at the current moment and the client matches its X window ID
-- Or if this client is already owned by some floater, return that floater.
function M.get_matching_floater(c)
    for floater_name, floater in pairs(M.floaters) do
        if floater.client == c then
            return floater
        end
        local wid = M.wid_storage:get(floater.name)
        if not floater:has_client() and wid and wid == c.window then
            return floater
        end
    end
end

-- Called when a new client appears but before default awful.rules handler.
function M.on_early_manage(c, startup)
    -- Maybe this client was requested by rule callback?
    if not startup and M._matched_rule_callback(c, startup, true) then
        return
    end
    local floater = M.get_matching_floater(c)

    if floater then
        floater:set_client(c)
        floater:init_client_early()
        return
    end

end

--- Called when a new client appears
function M.on_manage(c, startup)
    if not startup and M._matched_rule_callback(c, startup) then
        return
    end

    if not startup then -- we will try to recover lost floaters only after awesome.restart()
        return
    end

    -- Maybe this client was a floater and was "lost" after awesome restart? If so, restore the floater.
    --
    -- If we were brutally killed, we could have possibly not received
    -- the unmanage signal and the window id could be unrelated.
    if not rc.after_restart then
        return
    end
    local floater = M.get_matching_floater(c)

    if floater then
        floater:init_client_direct()
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
        return
    end
end

M._rule_callbacks = {}

-- TODO: Also will be perfectly replaced by deferreds....
function M._matched_rule_callback(c, startup, early)
    log:debug("Trying to match %s", c.name)
    for i, elem in ipairs(M._rule_callbacks) do
        if elem.floater:client_matches(c) then
            log:debug("Matched rule callback: %s early=%s", c.name, early)
            if early then
                elem.early_cb(c)
            else
                table.remove(M._rule_callbacks, i)
                elem.cb(c)
            end
            return true
        end
    end
end

function M._set_rule_callback(floater, cb, early_cb)
    log:debug("Setting rule callback for %s", floater.name)
    table.insert(M._rule_callbacks, {floater=floater, cb=cb, early_cb=early_cb})
end

--- Toggles floater `floater_name`.
function M.toggle(floater_name, show)
    log:debug("A toggle was requested for %s", floater_name)
    local floater = M.floaters[floater_name]
    floater:toggle(show)
end

--- Add Floater object and name it as `floater_name`
function M.add(floater)
    M.floaters[floater.name] = floater
    floater:on_added()
end

-- Setup signals
function M.setup()
    if not M._setup then
        M._setup = true
        utils.early_manage.setup()
        utils.pid_to_client.setup()
        capi.client.connect_signal("manage", M.on_manage)
        capi.client.connect_signal("early_manage", M.on_early_manage)
    end
end

return M
