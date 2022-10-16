local M = {}

local curl = require('plenary.curl')

--- {github_user}/{repo}
---@param text string
M.github = function(text)
    local res = curl.get('https://api.github.com/repos/' .. text)

    if res.status ~= 200 then
        return nil
    end

    local body = vim.fn.json_decode(res.body)
    if body == nil then
        return nil
    end

    return body.html_url
end

return M
