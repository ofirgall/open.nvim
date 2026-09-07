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

---Try all registered openers on text, return true if one succeeded.
---@param text string text to process
---@return boolean succeed
local function try_open(text)
    text = vim.fn.expand(text)
    for _, opener in pairs(M.openers) do
        local results = opener.open_fn(text, loaded_config.config)
        if open_results(opener, results) then
            return true
        end
    end
    return false
end

--- Find all pipe characters (│ or |) in a line with both byte positions and display columns.
---@param l string
---@return {byte_s: integer, byte_e: integer, vcol: integer}[]
local function pipe_positions(l)
    local pipes = {}
    local pos = 1
    while pos <= #l do
        if pos + 2 <= #l and l:sub(pos, pos + 2) == '│' then
            local vcol = vim.fn.strdisplaywidth(l:sub(1, pos - 1))
            table.insert(pipes, { byte_s = pos, byte_e = pos + 2, vcol = vcol })
            pos = pos + 3
        elseif l:sub(pos, pos) == '|' then
            local vcol = vim.fn.strdisplaywidth(l:sub(1, pos - 1))
            table.insert(pipes, { byte_s = pos, byte_e = pos, vcol = vcol })
            pos = pos + 1
        else
            pos = pos + 1
        end
    end
    return pipes
end

--- Given a line and target display-column pair, find the byte range between those pipes.
---@return integer|nil left_byte
---@return integer|nil right_byte
local function cell_byte_range(l, left_vcol, right_vcol)
    local pipes = pipe_positions(l)
    local lb, rb
    for _, p in ipairs(pipes) do
        if p.vcol == left_vcol then lb = p.byte_e + 1 end
        if p.vcol == right_vcol then rb = p.byte_s - 1 end
    end
    return lb, rb
end

--- Extract joined text from a table cell spanning multiple lines around the cursor.
--- Returns the joined cell text, or nil if the cursor is not in a recognizable table cell.
---@return string|nil
function M.extract_table_cell_text()
    local row = vim.fn.line('.')
    local byte_col = vim.fn.col('.')
    local line = vim.api.nvim_get_current_line()

    local pipes = pipe_positions(line)
    if #pipes < 2 then return nil end

    local left_vcol, right_vcol
    for i = 1, #pipes - 1 do
        if byte_col > pipes[i].byte_e and byte_col < pipes[i + 1].byte_s then
            left_vcol = pipes[i].vcol
            right_vcol = pipes[i + 1].vcol
            break
        end
    end
    if not left_vcol or not right_vcol then return nil end

    local separator_chars = { '─', '┼', '├', '┤', '┬', '┴', '═', '╪', '┌', '┐', '└', '┘' }
    local function is_separator(cell)
        local stripped = cell
        for _, ch in ipairs(separator_chars) do
            stripped = stripped:gsub(ch, '')
        end
        stripped = stripped:gsub('[%-%+= ]', '')
        return #stripped == 0
    end

    local start_row = row
    for r = row - 1, math.max(1, row - 50), -1 do
        local l = vim.fn.getline(r)
        local lb, rb = cell_byte_range(l, left_vcol, right_vcol)
        if not lb or not rb then break end
        if is_separator(l:sub(lb, rb)) then break end
        start_row = r
    end

    local end_row = row
    for r = row + 1, math.min(vim.fn.line('$'), row + 50) do
        local l = vim.fn.getline(r)
        local lb, rb = cell_byte_range(l, left_vcol, right_vcol)
        if not lb or not rb then break end
        if is_separator(l:sub(lb, rb)) then break end
        end_row = r
    end

    local parts = {}
    for r = start_row, end_row do
        local l = vim.fn.getline(r)
        local lb, rb = cell_byte_range(l, left_vcol, right_vcol)
        local cell = vim.trim(l:sub(lb, rb))
        if #cell > 0 then
            table.insert(parts, cell)
        end
    end

    if #parts == 0 then return nil end
    return table.concat(parts, '')
end

---Process the text in the openers
---@param text string text to process
M.open = function(text)
    if not try_open(text) then
        loaded_config.fallback(text)
    end
end

---Returns the file path under the cursor, joining multiline table cells when applicable.
---Falls back to `<cfile>`.
---@return string
---@usage `vim.keymap.set('n', 'gf', function() vim.cmd('edit ' .. require('open').file_under_cursor()) end)`
M.file_under_cursor = function()
    local cell_text = M.extract_table_cell_text()
    if cell_text and #cell_text > 0 then
        return cell_text
    end
    return vim.fn.expand('<cfile>')
end

---Alias for open.open(vim.fn.expand('<cWORD>'))
---@usage `vim.keymap.set('n', 'gx', require('open').open_cword)`
M.open_cword = function()
    local cell_text = M.extract_table_cell_text()
    if cell_text and try_open(cell_text) then
        return
    end

    local text = vim.fn.expand('<cWORD>')
    text = text:gsub('[%.,;:!%?%)%]]+$', '')
    M.open(text)
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
