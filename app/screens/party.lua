local ui = require("app.ui.ui")
local M = {}

function M.load(state, ctx)
    -- load actions
end

function M.draw(state)
    term.setCursorPos(2, 1)
    term.write("== Party ==")
    if not state.party then
        term.setCursorPos(2, 3)
        term.write("Failed to load :(")
    else
        for i, mon in ipairs(state.party) do
            term.setCursorPos(2, 2 + i)
            term.write(mon.name .. "  Lv" .. mon.level .. "  " .. mon.hp .. "hp")
        end
    end
    ui.button(2, 12, "Back", "goto:menu")
end

function M.handle(state, action, ctx)
    -- screen-specific actions
end

function M.onKey(state, ev, p1, ctx)

end

return M