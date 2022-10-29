---@mod open.openers.github GitHub shorthand opener.
local M = {}

local curl = require('plenary.curl')

---@type string The name of the opener: `github`
M.name = 'github'

--- Open GitHub repo shorthand in GitHub
---@param text string text to look for {github_user}/{repo}
---@return string|nil _ https://github.com/{github_user}/{repo}
M.open_fn = function(text)
    local github_shorthand = string.match(text, '[%w_%-%.]+/[%w_%-%.]+')
    if github_shorthand == nil then
        return nil
    end

    local res = curl.get('https://api.github.com/repos/' .. github_shorthand)

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
