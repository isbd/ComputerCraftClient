local core = require("app.api.core")

local M = {}

function M.getParty()
    return core.get("/party")
end

function M.swap(slot_a, slot_b)
    return core.post("/party/swap", {slot_a = slot_a, slot_b = slot_b})
end

function M.remove(slot)
    return core.post("/party/remove", {slot = slot})
end

function M.add(monster_id, slot)
    return core.get("/party/add", {monster_id = monster_id, slot = slot})
end

return M