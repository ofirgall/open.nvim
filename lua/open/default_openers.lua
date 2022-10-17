---@mod open.default_openers Default Openers
---@brief [[
---The default openers that comes with the plugin
---
---An opener is a function that receives a text to process and returns a uri to open.
---Return nil to do nothing (skip to the next opener)
---@brief ]]
local M = {}

local curl = require('plenary.curl')

--- Open GitHub repo shorthand in GitHub
---@param text string text to look for {github_user}/{repo}
---@return string|nil _ https://github.com/{github_user}/{repo}
M.github = function(text)
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

--- Open URLs (useful to strip quotes and such from URLs)
---@param text string text to look for valid URL
---@return string|nil _ the URL
M.url = function(text)
    return text:match("[http://][https://][http://www.][https://www.]+%w+%.%w+[/%w_%.%-]+")
end

return M
