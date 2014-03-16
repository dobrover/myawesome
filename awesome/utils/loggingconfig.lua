-- This is temporary, will replace with normal config soon

local logging = require 'logging'
local common = require 'common'

local LoggerWithDbg = common.baseclass.class({}, logging.Logger)

function LoggerWithDbg:dbg(...)
    local arg = table.pack(...)
    local tbl = {}
    for i = 1, arg.n do
        tbl[i] = tostring(arg[i])
    end
    self:debug(table.concat(tbl, ' '))
end

logging.setLoggerClass(LoggerWithDbg)

logging.basicConfig{
    filename='/var/awesome/root.log', level=logging.DEBUG,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",

}

local naughty = require 'naughty'

local AwesomeHandler = common.baseclass.class({}, logging.Handler)

function AwesomeHandler:emit(record)
    local title = record.name .. ':' .. record.levelname
    naughty.notify{text=self:format(record), title=title}
end

local awesomehdlr = AwesomeHandler(logging.DEBUG)

logging.getLogger(''):addHandler(awesomehdlr)

logging.getLogger('addons.dropdown'):setLevel(logging.DEBUG)