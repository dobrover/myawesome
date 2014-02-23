local wibox = require("wibox")
local awful = require("awful")
local utils = require("utils")
local M = {}

M.widget = wibox.widget.textbox()
M.widget:set_align("right")

function M.update()
   local fd = io.popen("amixer sget Master")
   local status = fd:read("*all")
   fd:close()
 
   local volume = string.match(status, "(%d?%d?%d)%%")
   volume = string.format("% 4d", volume)
   -- utils.dbg('.' .. volume .. '.')
   status = string.match(status, "%[(o[^%]]*)%]")

   if string.find(status, "on", 1, true) then
       -- For the volume numbers
       volume = volume .. "%"
   else
       -- For the mute button
       volume = volume .. "M"
   end
   volume = volume .. '|'
   M.widget:set_markup(utils.monospace(volume))
end

M.timer = utils.create_timer_and_fire(M.update, 60)

return M