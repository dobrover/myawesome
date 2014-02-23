-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Defined constants
require('constants')
-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")


-- Useful functions
utils = require("utils")
-- Used by awesome-client and evaluating lua code at prompt
dbg = utils.dbg

-- Global variables across rc.lua and subfiles
rc = {
    -- Default terminal
    terminal = "urxvt",
} 

-- Table of layouts to cover with awful.layout.inc, order matters.
rc.layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
}

-- {{{ Tags
-- Define a tag table which will hold all screen tags.
rc.tags = {                                                                                                                                                                                      
    names  = { "1w", "2msg ", "3trm", "4off", "5@", "6vmr", "7"},
    layout = { rc.layouts[1], rc.layouts[3], rc.layouts[6], rc.layouts[2], rc.layouts[2],
           rc.layouts[3], rc.layouts[3] }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    rc.tags[s] = awful.tag(rc.tags.names, s, rc.tags.layout)
end
-- }}}

--  Key and mouse bindings
local bindings = require('bindings')
root.keys(bindings.globalkeys)

-- General rules
awful.rules.rules = {
    -- Rule for all clients
    { 
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            keys = bindings.clientkeys,
            buttons = bindings.clientbuttons 
        } 
    },
}

-- {{{ Widgets and layout

-- Add widgets folder to path
package.path = string.format('%s;%s/widgets/?.lua',
                             package.path,
                             awful.util.getdir("config"))
rc.widgets = {}
rc.widgets.volume = require("volume")
rc.widgets.battery = require("battery")
rc.widgets.kbdd = require("kbdd")

local widgetlayout = require('widgetlayout')
widgetlayout.do_layout()

-- }}}

-- Dropdown module
rc.dropdown = require('dropdown')
do
    local urxvt_title = "dropdownURxvt"
    rc.dropdown.floaters["urxvt"] = {
        rule = {
          class = "URxvt",
          name = urxvt_title
        },
        properties = {
            floating = true,
        },
        -- Disable tabs because of bug https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=511377
        command = ("urxvt --title '%s' -pe '-tabbedex,-tabbed' "):format(urxvt_title),
        -- If negative, value will be taken as is. Otherwise it will be multiplied by workarea size.
        geometry = {x = 0.10, y = -20, width = 0.8, height = 0.5},
    }
end

-- Additional rules + dropdown rules
awful.rules.rules = awful.util.table.join(awful.rules.rules, 
    require('apprules'),
    rc.dropdown.get_rules_properties()
)

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}