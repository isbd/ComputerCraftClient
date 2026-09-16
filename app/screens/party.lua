local ui = require("app.ui.ui")
local panel = require("app.ui.panel")
local party_api = require("app.api.party")
local M = {}
local party
local monster_list = nil
local active_slot = nil
local party_size = 0

function fetchParty()
    local result, err = party_api.getParty()
    monster_list = result.monsters
    party_size = result.party_size
    active_slot = result.active_slot
    
    -- Dynamic panel to allow for potential future party size changes
    party = party or panel.newPanelList{
        x = 1, y = 3, width = 26, row_height = 2, visible_rows = 6,
        drawRow = function(mon, x, y, w)
            ui.fillRect(x, y, w, 1, colors.gray)
            term.setBackgroundColor(colors.gray)
            term.setCursorPos(x, y)
            if type(mon) == "number" then
                term.write(mon .. ":")
            else
                term.write(
                    mon.party_slot .. ":"..
                    mon.species.name .. " Lv".. mon.level .. " " ..
                    mon.current_hp .. "/" .. mon.max_hp .. "\3")
            end
            term.setBackgroundColor(colors.black)
            if type(mon) ~= "number" then
                ui.button(x + w - 4, y, " \18 ",  { type = "swap", monster = mon }, colors.white, colors.green, true)
                ui.button(x + w - 1, y, "\215",  { type = "remove", monster = mon }, colors.white, colors.red)
            end
        end
    }
    party:setItems(monster_list)
end

function M.load(state, ctx)
    fetchParty()
end

function M.draw(state)
    local text_hud = window.create(term.current(), 1, 1, ui.width, 1)
    term.setCursorBlink(false)
    term.clear()
    ui.renderWindowMessage(text_hud, "Party", colors.gray, colors.yellow)
    if not monster_list then
        term.setCursorPos(2, 3)
        term.write("Failed to load :(")
    else
        party:draw()
    end
    ui.button(1, 20, " Back ", "goto:menu")
end

function M.onScroll(state, dir, x, y, ctx)
    if party and party:contains(x, y) then
        party:onScroll(dir)
    end
end

function M.handle(state, action, ctx)
    if type(action.type) == "string" and action.type:sub(9) == "swap" then
        local target_slot = 0
        if action.type:sub(1, 8) == "mouse_l:" then
            target_slot = action.monster.party_slot + 1
        elseif action.type:sub(1, 8) == "mouse_r:" then
            target_slot = action.monster.party_slot - 1
        end
        local result, err = party_api.swap(action.monster.party_slot, target_slot)
        fetchParty()
    elseif action.type == "remove" then
        local result, err = party_api.remove(action.monster.party_slot)
        fetchParty()
    end
end

function M.onKey(state, ev, p1, ctx)
    if ev == "key" and p1 == keys.q then
        return "goto:menu"
    end
end

return M