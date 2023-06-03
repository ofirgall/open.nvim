local M = {}

local curl = require('plenary.curl')
local loaded_curl_opts = {}

function M.get(url, curl_opts)
    curl_opts = curl_opts or loaded_curl_opts
    return curl.get(url, curl_opts)
end

function M.setup(user_curl_opts)
    loaded_curl_opts = user_curl_opts
end

return M
