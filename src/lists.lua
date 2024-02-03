-- admin_mail/src/lists.lua
-- Handle mailing lists
--[[
    Copyright (C) 2024  1F616EMO

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
    USA
]]

-- Handle a cache of list of moderators
local list_admins = {}
local list_moderators = {}

minetest.after(0, function()
    local auth = minetest.get_auth_handler()

    for name in auth.iterate() do
        local data = auth.get_auth(name)
        local privs = minetest.get_player_privs(name)

        if privs.privs then
            list_admins[name] = true
        end

        if privs.ban then
            list_moderators[name] = true
        end
    end
end)

minetest.register_on_priv_grant(function(name, granter, priv)
    if priv == "privs" then
        list_admins[name] = true
    end

    if priv == "ban" then
        list_moderators[name] = true
    end
end)

minetest.register_on_priv_revoke(function(name, revoker, priv)
    if priv == "privs" then
        list_admins[name] = nil
    end

    if priv == "ban" then
        list_moderators[name] = nil
    end
end)


-- Handle mailing lists:
-- `admin_mail:admins` -> admins
-- `admin_mail:moderators` -> moderators AND admins

mail.register_recipient_handler(function(sender, name)
    if string.sub(name, 1, 11) ~= "admin_mail:" then
        return nil
    end

    local list_name = string.sub(name, 12)
    local list_dest = {}
    if list_name == "admins" or list_name == "moderators" then
        for k, v in pairs(list_admins) do
            list_dest[#list_dest+1] = k
        end

        if list_name == "moderators" then
            for k, v in pairs(list_moderators) do
                if list_name ~= "admins" or not list_admins[k] then
                    list_dest[#list_dest+1] = k
                end
            end
        end
    end

    if #list_dest == 0 then
        return false, "INVALID_MAILING_LIST"
    end

    return true, list_dest
end)