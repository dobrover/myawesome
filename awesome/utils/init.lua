local lfs = require('lfs')
local naughty = require('naughty')

-- TODO: Maybe move all functions somewhere down?

-- This function is only used to debug package loading (safe_require and package)
-- Just keep it if I suddenly decide to rewrite packaging
local function dbg(...)
    local printResult = ''
    local arg = {...}
    for i = 1, #arg do
        printResult = printResult .. tostring(arg[i]) .. (i == #arg and '' or ' ')
    end
    naughty.notify({text = printResult, timeout = 30})
end

local function safe_require(module_name)
    local status, module = pcall(require, module_name)
    return status and module or nil
end

local function package(package_name)
    local M = {__name = package_name}
    local mt = {
        __index = function (t, k) 
            local maybe_module = safe_require(package_name .. '.'  .. k)
            t[k] = maybe_module
            return maybe_module
        end
    }
    setmetatable(M, mt)
    return M
end

local utils = package(...)

utils.safe_require = safe_require
utils.package = package
utils.dbg = dbg

---If we are running under awesome
function utils.is_under_awesome()
    return arg == nil
end

function utils.create_timer_and_fire(func, interval)
    func()
    local new_timer = timer({ timeout = interval })
    new_timer:connect_signal("timeout", func)
    new_timer:start()
    return new_timer
end

function utils.run_after(seconds, func)
    local t = timer({timeout = seconds})
    t:connect_signal("timeout", function()
        t:stop()
        func()
    end)
    t:start()
    return t
end

function utils.monospace(text)
  return "<span face='monospace'>" .. text .. "</span>"
end

--- Yields result of applying mapper to every processes in /proc/
-- @mapper
function utils.processwalker(mapper) local function yielder()
    for dir in lfs.dir("/proc") do
        local pid = tonumber(dir)
        if pid ~= nil then
            local result = mapper(pid)
            if result ~= nil then
                coroutine.yield(pid, result)
            end
        end
    end
end return coroutine.wrap(yielder) end


--- Helper function for processwalker, returns a dict whose keys are @param fields 
--- and corresponding values are contents of files with the same name in /proc/<pid>/ directory
-- @param fields List of file names to be read into dict from /proc/<pid>/ directory
function utils.processfieldsmapper(fields)
    if type(fields) == 'string' then
        fields = {fields}
    end
    local function fields_mapper(pid)
        local result = {}
        for _, field in ipairs(fields) do
            local f, err = io.open("/proc/"..tostring(pid).."/"..field)
            if f then result[field] = f:read("*all") end
        end
        return result
    end
    return fields_mapper
end

return utils