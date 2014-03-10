local log = require('logging').getLogger(...)
local awful = require('awful')

local M = {}

function toggle_minimize_client (c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end

function M.do_layout()
    -- Create a wibox for each screen and add it
    mywibox = {}
    mypromptbox = {}
    mylayoutbox = {}
    -- List of tags on the left
    mytaglist = {}
    mytaglist.buttons = awful.util.table.join(
        awful.button({ }, MOUSE_BTN_LEFT, awful.tag.viewonly),
        awful.button({ modkey }, MOUSE_BTN_LEFT, awful.client.movetotag),
        awful.button({ }, MOUSE_BTN_RIGHT, awful.tag.viewtoggle),
        awful.button({ modkey }, MOUSE_BTN_RIGHT, awful.client.toggletag)
    )
    -- List of tasks
    mytasklist = {}
    mytasklist.buttons = awful.util.table.join(
        awful.button({ }, 1, unminimize_client)
    )

    for s = 1, screen.count() do
        -- Create the screen wibox
        mywibox[s] = awful.wibox({ position = "top", screen = s })

        -- {{ Widgets that are aligned to the left

        -- Create a taglist widget
        mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

        -- Create a promptbox for each screen
        mypromptbox[s] = awful.widget.prompt()

        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(mytaglist[s])
        left_layout:add(mypromptbox[s])
        -- }}

        -- {{ Widgets that are aligned to the right

        -- Create an imagebox widget which will contains an icon indicating which layout we're using.
        -- We need one layoutbox per screen.
        mylayoutbox[s] = awful.widget.layoutbox(s)
        mylayoutbox[s]:buttons(awful.util.table.join(
            awful.button({ }, MOUSE_BTN_LEFT, function () awful.layout.inc(rc.layouts, 1) end),
            awful.button({ }, MOUSE_BTN_RIGHT, function () awful.layout.inc(rc.layouts, -1) end)
        ))

        local right_layout = wibox.layout.fixed.horizontal()
        if s == 1 then right_layout:add(wibox.widget.systray()) end
        -- Add my widgets
        local separator = wibox.widget.textbox()
        separator:set_markup(utils.monospace(" "))
        right_layout:add(awful.widget.textclock("%a %d %b %H:%M ", 60))
        right_layout:add(mylayoutbox[s])
        right_layout:add(separator)
        right_layout:add(rc.widgets.kbdd.widget)
        right_layout:add(rc.widgets.battery.widget)
        right_layout:add(rc.widgets.volume.widget)
        -- }}

        -- {{ Widgets in the middle

        -- Create a tasklist widget
        mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
        -- }}

        -- Now bring it all together (with the tasklist in the middle)
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_middle(mytasklist[s])
        layout:set_right(right_layout)

        mywibox[s]:set_widget(layout)

    end
end

return M