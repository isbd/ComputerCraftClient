local ui = require("app.ui.ui")
local M = {}

function M.load(state, ctx)
    -- load actions
end

function M.draw(state)

    term.setCursorBlink(false)
    term.clear()
    local text_hud = window.create(term.current(), 1, 1, ui.width, 1)
    ui.renderWindowMessage(text_hud, "Monster Game", colors.gray, colors.yellow)
    ui.button(2, 3, " Echo Hunter ", "goto:hunt")
    ui.button(2, 5, " Party ", "goto:party")
    ui.button(2, 7, " MonManager ", "goto:monmanager")
    ui.button(2, 9, " Challenge ", "goto:challenge")
    ui.button(2, 11, " Shop ", "goto:shop")
    ui.button(1, ui.height, " Quit ",  "quit")
end

function M.handle(state, action, ctx)

end

function M.onKey(state, ev, p1, ctx)

end

return M