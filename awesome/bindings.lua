local awful = require('awful')

local M = {}

-- Default modkey.
local modkey = "Mod4"

local function eval_lua_prompt()
    awful.prompt.run({ prompt = "Run Lua code: " },
    mypromptbox[mouse.screen].widget,
    awful.util.eval, nil,
    awful.util.getdir("cache") .. "/history_eval")
end

local function switch_focus(switch_function)
    switch_function()
    if client.focus then client.focus:raise() end
end

local function do_restart()
    rc.storage:set('rc.after_restart', true)
    awesome.restart()
end

-- {{{ Key bindings
M.globalkeys = awful.util.table.join(
    -- Tag navigation
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ), -- Previous tag
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ), -- Next tag
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore), -- Go to previous tag in history

    -- Mod+WASD navigation
    awful.key({ modkey,           }, "a", function () switch_focus(function ()
            awful.client.focus.bydirection('left')
    end) end),

    awful.key({ modkey,           }, "d", function () switch_focus(function ()
        awful.client.focus.bydirection('right')
    end) end),

    awful.key({ modkey,           }, "w", function ()switch_focus(function ()
        awful.client.focus.bydirection('up')
    end) end),

    awful.key({ modkey,           }, "s", function () switch_focus(function ()
        awful.client.focus.bydirection('down')
    end) end),

    -- And j,k navigation also for floating windows

    awful.key({ modkey,           }, "j", function() switch_focus(function ()
        awful.client.focus.byidx(1)
    end) end),
    awful.key({ modkey,           }, "k", function () switch_focus(function ()
        awful.client.focus.byidx(1)
    end) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(rc.terminal) end),
    awful.key({ modkey, "Control" }, "r", do_restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    -- Resizing
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),

    -- Increase/decrease amount of master windows
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),

    -- Next/previous layout 
    awful.key({ modkey,           }, "space", function () awful.layout.inc(rc.layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(rc.layouts, -1) end),

    -- Dropdown terminal
    awful.key({ modkey,           }, "`",     function () rc.dropdown.toggle("urxvt") end),

    -- Gvim notes
    awful.key({ modkey,           }, "F1",     function () rc.dropdown.toggle("gvim_notes") end),
    -- Temporary, just for demonstration of gvim that forks and can't be tracked by pid.
    awful.key({ modkey,           }, "F12",     function () rc.dropdown.toggle("gvim_notes_rules") end),

    -- Sound control
    awful.key({ }, "XF86AudioRaiseVolume", function ()
        awful.util.spawn("amixer set Master 5%+", false) rc.widgets.volume.update() 
    end),
    awful.key({ }, "XF86AudioLowerVolume", function ()
        awful.util.spawn("amixer set Master 5%-", false) rc.widgets.volume.update() 
    end),
    awful.key({ }, "XF86AudioMute", function ()
        awful.util.spawn("amixer set Master toggle", false) rc.widgets.volume.update()
    end),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessUp", function () awful.util.spawn("xbacklight -inc 10", false) end),
    awful.key({ }, "XF86MonBrightnessDown", function () awful.util.spawn("xbacklight -dec 10", false) end),

    awful.key({ }, "Print", function () awful.util.spawn("scrot -e 'mv $f ~/.screenshots/ 2>/dev/null'", false) end),
    
    -- Deadbeef audio control
    awful.key({ }, "XF86AudioPlay", function () awful.util.spawn("deadbeef --toggle-pause", false) end),
    awful.key({ }, "XF86AudioPrev", function () awful.util.spawn("deadbeef --prev", false) end),
    awful.key({ }, "XF86AudioNext", function () awful.util.spawn("deadbeef --next", false) end),
    awful.key({ }, "XF86AudioStop", function () awful.util.spawn("deadbeef --stop", false) end),

    -- Prompt
    awful.key({ modkey }, "r",     function () mypromptbox[mouse.screen]:run() end),

    -- Eval Lua code
    awful.key({ modkey }, "x", eval_lua_prompt),

    -- Restore a random minimized client
    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Restore all minimized clients on current tag
    awful.key({ modkey, "Shift"   }, "n", function()
        local tag = awful.tag.selected()
        for i=1, #tag:clients() do
            tag:clients()[i].minimized=false
        end
    end)
)

M.clientkeys = awful.util.table.join(
    -- Fullscreen
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    -- Kill client
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    -- Toggle client floating
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    -- Toggle client ontop
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = true               end),
    awful.key({ modkey,           }, "m", function (c)
        c.maximized_horizontal = not c.maximized_horizontal
        c.maximized_vertical   = not c.maximized_vertical
    end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    M.globalkeys = awful.util.table.join(M.globalkeys,
        -- View tag #i
        awful.key({ modkey }, "#" .. i + 9, function ()
            local screen = mouse.screen
            local tag = awful.tag.gettags(screen)[i]
            if tag then
                awful.tag.viewonly(tag)
            end
        end),
        -- Toggle tag #i
        awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
            local screen = mouse.screen
            local tag = awful.tag.gettags(screen)[i]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end),
        -- Move client to tag #i
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
                if client.focus then
                    local tag = awful.tag.gettags(client.focus.screen)[i]
                    if tag then
                        awful.client.movetotag(tag)
                    end
                end
        end),
        -- Toggle client on tag #i
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function ()
            if client.focus then
                local tag = awful.tag.gettags(client.focus.screen)[i]
                if tag then
                    awful.client.toggletag(tag)
                end
            end
        end)
    )
end

M.clientbuttons = awful.util.table.join(
    awful.button({ }, MOUSE_BTN_LEFT, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, MOUSE_BTN_LEFT, awful.mouse.client.move),
    awful.button({ modkey }, MOUSE_BTN_RIGHT, awful.mouse.client.resize))

return M
