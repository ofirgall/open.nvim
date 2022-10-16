---@mod open.nvim Introduction
---@brief [[
---System open current word from vim.
---For example: open 'ofirgall/open.nvim' in github in your browser.
---@brief ]]

---@mod open Open
local M = {}

local system_open = require('open.system_open')

local default_config = {
    openers = require('open.default_openers'),
    fallback = function(text)
        system_open.open(text)
    end,
    system_open = {
        cmd = "",
        args = {},
    },
}

local loaded_config = default_config

---@param config table user config
---@usage [[
----- Default config
---require('open').setup {
---     -- all the default openers
---    openers = require('open.default_openers'),
---     -- fallback function if no opener succeeds
---    fallback = function(text)
---        system_open.open(text)
---    end,
---    -- Override system opener, the defaults should work out of the box
---    system_open = {
---        cmd = "",
---        args = {},
---    },
---}
---@usage ]]
M.setup = function(config)
    config = config or {}
    config = vim.tbl_deep_extend('keep', config, default_config)

    loaded_config = config
    system_open.setup(loaded_config)
end

---Process the text in the setup.openers
---@param text string text to process
M.open = function(text)
    for _, opener_fn in pairs(loaded_config.openers) do
        local res = opener_fn(text)
        if res ~= nil then
            system_open.open(res)
            return
        end
    end

    loaded_config.fallback(text)
end

---Alias for open.open(vim.fn.expand('<cWORD>'))
M.open_cword = function()
    M.open(vim.fn.expand('<cWORD>'))
end

return M
