-- This is temporary, will replace with normal config soon

local logging = require 'logging'
local common = require 'common'

logging.basicConfig{
    filename='/var/awesome/root.log', level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s"
}

local naughty = require 'naughty'

local AwesomeHandler = common.baseclass.class({}, logging.Handler)

function AwesomeHandler:emit(record)
    local title = record.name .. ':' .. record.levelname
    naughty.notify{text=self:format(record), title=title}
end

local awesomehdlr = AwesomeHandler(logging.WARN)

logging.getLogger(''):addHandler(awesomehdlr)