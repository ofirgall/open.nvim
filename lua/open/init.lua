---@mod open.nvim Introduction
---@brief [[
---System open current word from vim.
---For example: open 'ofirgall/open.nvim' in github in your browser.
---@brief ]]

---@toc open.table-of-contents

---@mod open Open
local M = {}

local system_open = require('open.system_open')

local default_config = {
    config = {
        system_open = {
            cmd = "",
            args = {},
        },
        curl = {
        },
    },
    disabled_openers = {
    },
    fallback = function(text)
        system_open.open(text, {})
    end,
    openers_config = {
    }
}

local loaded_config = default_config

---@type Opener[]
local DEFAULT_OPENERS = {
    require('open.openers.github'),
    require('open.openers.url'),
}

---@param opts table user config
---@usage [[
----- Default config
---require('open').setup {
---    config = {
---        -- Override system opener, the defaults should work out of the box
---        system_open = {
---            cmd = "",
---            args = {},
---        },
---        -- Options to pass to plenary.curl
---        curl_opts = {
---            -- compressed = false -- Uncomment this line to disable curl compression
---        },
---    },
---    -- List of disabled openers, 'github' for example see `:help open.default_openers`
---    disabled_openers = {
---    },
---    -- fallback function if no opener succeeds
---    fallback = function(text)
---        system_open.open(text)
---    end,
---    -- Override `config` per opener
---    openers_config = {
---        -- Override `jira` browser for example
---        ['jira'] = {
---            system_open = {
---                cmd = 'chromium-browser',
---            },
---        },
---    },
---}
---@usage ]]
M.setup = function(opts)
    -- migrate user config
    opts.config = opts.config or {}
    opts.config.system_open = opts.system_open
    opts.config.curl = opts.curl_opts

    opts = opts or {}
    opts = vim.tbl_deep_extend('keep', opts, default_config)

    -- Register default openers
    for _, opener in ipairs(DEFAULT_OPENERS) do
        local disabled = false
        for _, disabled_opener in ipairs(opts.disabled_openers) do
            if opener.name == disabled_opener then
                disabled = true
                break
            end
        end

        if not disabled then
            M.register_opener(opener)
        end
    end

    loaded_config = opts
    system_open.setup(loaded_config)
    require('open.common.curl').setup(loaded_config.config.curl)
end

---Open results
---@param opener string opener name
---@param results string[] uris
---@return boolean succeed
local function open_results(opener, results)
    if results ~= nil then
        local len = #results
        if len == 0 then
            return false
        end

        local opts = loaded_config.openers_config[opener.name] or {}
        vim.print(opener.name)
        if len == 1 then
            system_open.open(results[1], opts['system_open'])
            return true
        end

        vim.ui.select(results, {}, function(item, index)
            _ = index
            system_open.open(item, opts['system_open'])
        end)
        return true
    end

    return false
end

---Process the text in the openers
---@param text string text to process
M.open = function(text)
    for _, opener in pairs(M.openers) do
        local results = opener.open_fn(text, loaded_config.config)

        if open_results(opener, results) then
            return
        end
    end

    loaded_config.fallback(text)
end

---Alias for open.open(vim.fn.expand('<cWORD>'))
---@usage `vim.keymap.set('n', 'gx', require('open').open_cword)`
M.open_cword = function()
    M.open(vim.fn.expand('<cWORD>'))
end

---@class Opener
---@field name string Name of the opener.
---@field open_fn fun(text: string, opts: table): string[] Function to process text to uris. Returns the uri's to open or nil to do nothing (skips to the next opener).

M.openers = {}

---Register an opener.
---
---@param opener Opener
---@usage[[
---M.register_opener({
---    name = 'Example Opener',
---    open_fn = function(text, opts)
---        return { 'www.example.org' }
---    end
---})
---@usage]]
M.register_opener = function(opener)
    assert(type(opener) == 'table', 'opener: expected table but got ' .. type(opener))
    assert(type(opener.name) == 'string', 'opener.name: expected string but got ' .. type(opener.name))
    assert(type(opener.open_fn) == 'function', 'opener.open_fn: expected function but got ' .. type(opener.open_fn))

    table.insert(M.openers, opener)
end

return M
