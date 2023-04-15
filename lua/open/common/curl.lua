local M = {}

local curl = require('plenary.curl')
local curl_opts = {}

function M.get(url)
    return curl.get(url, curl_opts)
end

function M.setup(user_curl_opts)
    curl_opts = user_curl_opts
end

return M
