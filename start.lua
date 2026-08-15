local core = require("app.core")

local args = { ... }
local config_file = args[1] or "config.json"

core.run(config_file)