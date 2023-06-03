-- Credit: https://github.com/nvim-tree/nvim-tree.lua
local uv = vim.loop

local M = {
    config = {
        is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win32unix" == 1,
        is_macos = vim.fn.has "mac" == 1 or vim.fn.has "macunix" == 1,
        is_unix = vim.fn.has "unix" == 1,
    },
}

function M.open(uri, opts)
    if #M.config.system_open.cmd == 0 then
        error("open.nvim: Cannot open file with system application. Unrecognized platform.")
        return
    end

    opts = opts or {}
    local cmd = opts['cmd'] or M.config.system_open.cmd
    local args = opts['args'] or M.config.system_open.args

    local process = {
        cmd = cmd,
        args = args,
        errors = "\n",
        stderr = uv.new_pipe(false),
    }
    table.insert(process.args, uri)
    process.handle, process.pid = uv.spawn(
        process.cmd,
        { args = process.args, stdio = { nil, nil, process.stderr }, detached = true },
        function(code)
            process.stderr:read_stop()
            process.stderr:close()
            process.handle:close()
            if code ~= 0 then
                process.errors = process.errors .. string.format("open.nvim system_open: return code %d.", code)
                error(process.errors)
            end
        end
    )
    table.remove(process.args)
    if not process.handle then
        error("\n" .. process.pid .. "\nopen.nvim system_open: failed to spawn process using '" .. process.cmd .. "'.")
        return
    end
    uv.read_start(process.stderr, function(err, data)
        if err then
            return
        end
        if data then
            process.errors = process.errors .. data
        end
    end)
    uv.unref(process.handle)
end

function M.setup(opts)
    M.config.system_open = opts.config.system_open or {}

    if #M.config.system_open.cmd == 0 then
        if M.config.is_windows then
            M.config.system_open = {
                cmd = "cmd",
                args = { "/c", "start", '""' },
            }
        elseif M.config.is_macos then
            M.config.system_open.cmd = "open"
        elseif M.config.is_unix then
            M.config.system_open.cmd = "xdg-open"
        end
    end
end

return M
