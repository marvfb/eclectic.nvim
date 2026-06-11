local M = {}

local config = require("eclectic.common.config")

function M.setup(user_config)
	config.apply_config(user_config)
end

return M
