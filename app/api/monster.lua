local core = require("app.api.core")

local M = {}

function M.getMonsters()
    return core.get("/monster/")
end

function M.getMonster(monster_id)
    return core.get("/monster/" .. monster_id)
end

return M