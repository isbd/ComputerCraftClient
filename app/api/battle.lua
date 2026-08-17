local core = require("app.api.core")

local M = {}

function M.attack(slot)
    return core.post("/battle/attack", { attack_id = slot })
end

function M.catch()
    return core.post("/battle/catch")
end

function M.getMoves()
    return core.get("/battle/moves")
end

return M