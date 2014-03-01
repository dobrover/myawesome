require "luarocks.loader"

local M = {}

local utils = require('utils')
local logging = require('logging')

local logger = nil

if utils.is_under_awesome() then
    -- TODO: Add different presets for levels.
    local naughty = require('naughty')
    logger = logging.new(function (log, lvl, msg)
        naughty.notify({text=msg})
    end)
else
    local log_console = require('logging.console')
    logger = log_console()
end

for i, level in ipairs({'debug', 'info', 'warn', 'error', 'fatal'}) do
    M[level] = function (...) logger[level](logger, ...) end
end

return M