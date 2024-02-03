-- admin_mail/src/report.lua
-- Handle GUI and chatcommand
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

local S = minetest.get_translator("admin_mail")
local gui = flow.widgets

local function send_report_mod(from, dest, title, content)
    content = content .. "\n\n" .. S("This is a mail sent via the /report GUI.")

    local success, err = mail.send({
        from = from,
        to = dest,
        subject = title,
        body = content
    })

    return success, err
end

local function send_report_pl(from, dest, title, content)
    content = table.concat({
        S("Dear @1,", from),
        "",
        S("Thank you for contacting the moderation team. We hereby confirm that your mail has been successfully sent."),
        S("The original message is attached below. Should you have any questions, you can fill in the form again."),
        "",
        S("Yours truly,"),
        S("The Moderation Team"),
        "",
        "=== " .. S("Original message") .. " ===",
        S("Title: @1", title),
        "",
        content
    }, "\n")

    mail.send({
        from = dest,
        to = from,
        subject = S("We have received your form"),
        body = content
    })
end

local function send_report(from, dest, title, content)
    local success_m, err_m = send_report_mod(from, dest, title, content)
    if success_m == false then
        return false, err_m
    end

    send_report_pl(from, dest, title, content)
    return true
end

admin_mail.report_gui = flow.make_gui(function(player, ctx)
    ctx.tab = ctx.tab or "main"

    if ctx.tab == "main" then
        return gui.VBox {
			gui.HBox { -- Navbar
				gui.Label { label = S("Moderation Team Contact Form"), expand = true, align_h = "left" },
				gui.ButtonExit {
					w = 0.7,
					h = 0.7,
					label = "x",
				},
			},
            gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
            gui.HBox {
                gui.Textarea {
                    h = 1.5, w = 9,
                    default = table.concat({
                        S("Use this form to contact moderators."),
                        S("If the issue should not be disclosed, choose \"Admins\";"),
                        S("otherwise, choose \"Moderators\".")
                    }, "\n"),
                    expand = true, align_h = "left"
                },
                gui.Dropdown {
                    h = 1,
                    name = "dest",
                    items = {
                        S("Moderators"),
                        S("Admins"),
                    },
                    selected_idx = 1,
                    index_event = true,
                }
            },
            gui.Field {
                name = "title",
                label = S("Title"),
            },
            gui.Textarea {
                name = "content",
                label = S("Write your messages here..."),
                h = 6.5,
            },
            gui.HBox {
                gui.Textarea {
                    h = 1, w = 10,
                    default = S("Please include sufficient information\n" ..
                        "for the moderation team to handle your request."),
                    expand = true, align_h = "left"
                },
                gui.ButtonExit {
                    label = S("Submit"),
                    on_event = function(player, ctx)
                        local dest = "admin_mail:moderators"
                        if ctx.form.dest == 2 then
                            dest = "admin_mail:admins"
                        end

                        local name = player:get_player_name()

                        if not(ctx.form.content and ctx.form.content ~= "") then
                            minetest.chat_send_player(name, S("The message cannot be blank."))
                            return
                        end

                        local title = ctx.form.title
                        if not(title and title ~= "") then
                            title = S("NO TITLE")
                        end

                        local success, err = send_report(name, dest, title, ctx.form.content)
                        if success then
                            minetest.chat_send_player(name, S("Message sent."))
                        else
                            minetest.chat_send_player(name, S("Failed to send message: @1", err))
                        end
                    end
                }
            },
        }
    end
end)

minetest.register_chatcommand("report", {
    description = S("Contact moderators for player mishevaiour or server issues."),
    func = function(name, params)
        local player = minetest.get_player_by_name(name)
        if not player then return false end

        admin_mail.report_gui:show(player)
        return true, S("Form shown.")
    end
})
