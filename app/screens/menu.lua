local ui = require("app.ui.ui")
local M = {}

function M.load(state, ctx)
    -- load actions
end

function M.draw(state)
    term.setCursorPos(2, 1)
    term.write("== Monster Game ==")
    ui.button(2, 3, "Party", "goto:party")
    ui.button(2, 5, "Challenge", "goto:challenge")
    ui.button(2, 7, "Fish", "goto:fish")
    ui.button(2, 9, "MonManager", "goto:monmanager")
    ui.button(2, 11, "Quit",  "quit")
end

function M.handle(state, action, ctx)
    -- screen-specific actions
end

function M.onKey(state, ev, p1, ctx)

end

return M