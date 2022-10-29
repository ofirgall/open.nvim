---@mod open.openers.url Open URLs (useful to strip quotes and such from URLs)
local M = {}

---@type string The name of the opener: `uri`
M.name = 'url'

--- Open URLs
---@param text string text to look for valid URL
---@return string[]|nil _ the URL
M.open_fn = function(text)
    local urls = {}
    for url in text:gmatch("[http://][https://][http://www.][https://www.]+%w+%.%w+[/%w_%.%-%~]+") do
        table.insert(urls, url)
    end

    return urls
end

return M
