local capi = {
    client = client,
}
local aclient = require('awful.client')
local atag = require('awful.tag')
local log = require('logging').getLogger(...)

local M = {}

--- Apply properties to a client.
--- This was stoled from awful/rules.lua :(
--- TODO: Maybe send them a proposition and a patch to split their rules function?
-- @param c The client.
-- @param entries_list List of entries (exactly like those in awful.rules.rules)
function M.apply_to_client(c, entries_list)
    local props = {}
    local callbacks = {}
    for _, entry in ipairs(entries_list) do
        if entry.properties then
            for property, value in pairs(entry.properties) do
                props[property] = value
            end
        end
        if entry.callback then
            table.insert(callbacks, entry.callback)
        end
    end

    for property, value in pairs(props) do
        if property ~= "focus" and type(value) == "function" then
            value = value(c)
        end
        if property == "floating" then
            aclient.floating.set(c, value)
        elseif property == "tag" then
            c:tags({ value })
            c.screen = atag.getscreen(value)
        elseif property == "switchtotag" and value and props.tag then
            atag.viewonly(props.tag)
        elseif property == "height" or property == "width" or
                property == "x" or property == "y" then
            local geo = c:geometry();
            geo[property] = value
            c:geometry(geo);
        elseif property == "focus" then
            -- This will be handled below
        elseif type(c[property]) == "function" then
            c[property](c, value)
        else
            c[property] = value
        end
    end

    -- If untagged, stick the client on the current one.
    if #c:tags() == 0 then
        atag.withcurrent(c)
    end

    -- Apply all callbacks from matched rules.
    for i, callback in pairs(callbacks) do
        callback(c)
    end

    -- Do this at last so we do not erase things done by the focus
    -- signal.
    if props.focus and (type(props.focus) ~= "function" or props.focus(c)) then
        client.focus = c
    end
end

return M