local core = require("app.api.core")

local M = {}

function M.get_monsters()
    return core.get("/monster/")
end

function M.get_monster(monster_id)
    return core.get("/monster/" .. monster_id)
end

return M