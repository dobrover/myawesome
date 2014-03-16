local memstorage = {}

local log = require('logging').getLogger(...) 
local oo = require 'loop.simple'
local common = require'common'

-- Remove a dot separated prefix from key, returns nil if there is no such prefix.
-- chop_prefix('a.b.bcd', 'a.b') -> 'bcd'
local function chop_prefix(key, prefix)
    local prefix_len = prefix:len()
    if prefix_len > 0 then
        if key:sub(1, prefix_len) == prefix then
            if key:sub(prefix_len + 1, prefix_len + 1) == '.' then
                return key:sub(prefix_len + 2, key:len())
            end
        end
    else
        return key
    end
end

local function add_prefix(key, prefix)
    if prefix and prefix:len() > 0 then
        return prefix .. '.' .. key
    else
        return key
    end
end

function memstorage._deserialize(s)
    local prefix = s:sub(1, 1)
    local data = s:sub(2, s:len())
    local obj = nil
    if prefix == 's' then
        obj = data
    elseif prefix == 'n' then
        obj = tonumber(data)
        if not obj then
            error("Can't deserialize number: " .. data)
        end
    elseif prefix == 'b' then
        if data == '1' then
            obj = true
        elseif data == '0' then
            obj = false
        else
            error("Cant deserialize boolean value: " .. data)
        end
    elseif prefix == '0' then
        obj = nil
    else
        error("Unrecognized prefix: " .. prefix)
    end
    return obj
end

function memstorage._serialize(obj)
    local prefix, data = '', ''
    if type(obj) == 'string' then
        prefix = 's'
        data = obj
    elseif type(obj) == 'number' then
        prefix = 'n'
        data = tostring(obj)
    elseif type(obj) == 'boolean' then
        prefix = 'b'
        data = obj and '1' or '0'
    elseif type(obj) == 'nil' then
        prefix = '0'
        data = ''
    else
        error(("Unserializable object! %s"):format(obj))
    end
    return prefix .. data
end

-- A simple key-value storage
local Memstorage = common.baseclass.class()
memstorage.Memstorage = Memstorage

function Memstorage:__create(backend)
    self.backend = backend
    self.storage = self:load()
end

function Memstorage:load()
    local result = {}
    local values = self.backend:load()
    for k, v in pairs(values) do
        result[k] = memstorage._deserialize(v)
    end
    return result
end

function Memstorage:set(key, value)
    self.backend:set(key, memstorage._serialize(value))
    self.storage[key] = value
end

function Memstorage:get(key)
    return self.storage[key]
end

-- Adapter for Memstorage for autoprefixing key names.

local MemstorageAdapter = common.baseclass.class()
memstorage.MemstorageAdapter = MemstorageAdapter

function MemstorageAdapter:__create(ms, prefix)
    self.ms = ms
    self.prefix = prefix or ''
end

function MemstorageAdapter:set(key, value)
    self.ms:set(add_prefix(key, self.prefix), value)
end

function MemstorageAdapter:get(key)
    return self.ms:get(add_prefix(key, self.prefix))
end

-- Backend for Memstorage
local Backend = common.baseclass.class()
memstorage.Backend = Backend

function Backend:load()
end

function Backend:set(key, value)
end

-- Simple backend based on table
local SimpleBackend = common.baseclass.class()
memstorage.SimpleBackend = SimpleBackend

function SimpleBackend:__create(tbl)
    self.tbl = tbl
end

function SimpleBackend:load()
    return self.tbl
end

function SimpleBackend:set(key, value)
    self.tbl[key] = value
end

-- X server backend based on xrdb

local XrdbBackend = common.baseclass.class()
memstorage.XrdbBackend = XrdbBackend

function XrdbBackend:__create(prefix)
    oo.superclass(XrdbBackend).__create(self)
    self.prefix = prefix
end

function XrdbBackend:load()
    local result = {}
    local fd = io.popen('xrdb -query')
    local data = fd:read('*all')
    fd:close()
    for line in data:gmatch("[^\n]+") do
        local chopped = chop_prefix(line, self.prefix)
        if chopped then
            local i = chopped:find(':\t')
            local key = chopped:sub(1, i - 1)
            local value = chopped:sub(i + 2, chopped:len())
            result[key] = value
        end
    end
    return result
end

function XrdbBackend:set(key, value)
    local full_key = add_prefix(key, self.prefix)
    local fd = io.popen('xrdb -merge', 'w')
    local to_write = full_key .. ': ' .. value .. '\n'
    fd:write(to_write)
    fd:close()
end

return memstorage