local naughty = require('naughty')
local utils = require('utils')

local M = {}
-- If less then LOW_THRESHOLD% battery left, notify
M.LOW_THRESHOLD = 11
-- or shout
M.VERY_LOW_THRESHOLD = 5

local function trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

M.widget = wibox.widget.textbox()    

M.update = function() 
    local fh = assert(io.popen("acpi", "r"))
    local status = fh:read("*l")
    local is_discharging = (status:find("Discharging") ~= nil)
    local battery_left = tonumber(status:match("(%d+)%%")) -- " 23%" -> 23
    if battery_left <= M.LOW_THRESHOLD and is_discharging then
    	local preset = naughty.config.presets.normal
    	if battery_left <= M.VERY_LOW_THRESHOLD then
    		preset = naughty.config.presets.critical
    	end 
    	naughty.notify({
    		title="Battery low!",
    		text=("Only %d%% left, plug in the charger!"):format(battery_left),
    		preset=preset,
    		timeout=20,
    	})
    end
    local charge_arrow = (is_discharging and "v" or "^")
    if status:find("discharging at zero rate") ~= nil then
    	charge_arrow = " "
    end
    local widget_text = ("BAT:%d%%%s|"):format(battery_left, charge_arrow)
    M.widget:set_markup(utils.monospace(widget_text))
    fh:close()    
end       

M.timer = utils.create_timer_and_fire(M.update, 60)

return M