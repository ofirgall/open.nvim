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

M.setup = function(config)
    config = config or {}
    config = vim.tbl_deep_extend('keep', config, default_config)

    loaded_config = config
    system_open.setup(loaded_config)
end

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

M.open_cword = function()
    M.open(vim.fn.expand('<cWORD>'))
end

return M
