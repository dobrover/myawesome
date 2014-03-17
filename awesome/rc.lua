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

-- Useful functions
utils = require("utils")
utils.early_manage.setup()
-- Logging config
require 'utils.loggingconfig'
local log = require('logging').getLogger('rc')


-- Defined constants
require('constants')
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- Global variables across rc.lua and subfiles
rc = {
    -- Default terminal
    terminal = "urxvt",
} 

-- Memstorage
local memstorage = utils.memstorage
local storage_backend = memstorage.XrdbBackend('Xstorage.AWM')
rc.storage = memstorage.Memstorage(storage_backend)

rc.after_restart = rc.storage:get('rc.after_restart')
if rc.after_restart then
    rc.storage:set('rc.after_restart', false)
end

function rc.get_storage(prefix)
    return utils.memstorage.MemstorageAdapter(rc.storage, prefix or '')
end

-- TOODO!
-- Logging - human-readable config!
-- Move utils functions to submodules
-- Write deferreds (basic verison very)
-- Dropdown by rule or path
-- Memstorage - cheap get, costly set, set -> also sets to cache
-- Add timeout to deferreds

-- Idea - turn dropdown into a normal window. How? Apply back client keys (basically backup everything when making it)
-- Also add a button to make a normal window into dropdown. Cool!


rc.utils = utils
rc.logger = logger -- Just for conveniency.
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

local apprules = require('apprules')

-- General rules
awful.rules.rules = awful.util.table.join(awful.rules.rules, {
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
    },
    apprules.permanent_rules
)

-- TODO: Fix this
-- {{{ Widgets and layout

-- Add widgets folder to path

rc.widgets = require('widgets')

local widgetlayout = require('widgetlayout')
widgetlayout.do_layout()

-- }}}

-- Miscelaneous stuff
rc.misc = require('addons.misc')
-- Dropdown module
rc.dropdown = require('addons.dropdown')
rc.dropdown.setup()
do
    rc.dropdown.add(rc.dropdown.Floater{
        name = "urxvt",
        properties = {
            floating = true,
        },
        command = "urxvt",
        geometry = {x = -0.10, y = 20, width = -0.8, height = -0.5},
        keep_in_background = true,
    })
    rc.dropdown.add(rc.dropdown.Floater{
        name = "gvim_notes",
        properties = {
            floating = true,
        },
        command = "gvim --nofork -n -y -S ~/notes/.gvimrc -p4 /home/y/notes/notes1 /home/y/notes/notes2 /home/y/notes/notes3 /home/y/notes/.gvimrc",
        geometry = {x = -0.10, y = 20, width = -0.8, height = -0.5},
    })
end

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
