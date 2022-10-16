local M = {}

local system_open = require('open.system_open')

local default_config = {
	openers = require('open.default_openers'),
	---@diagnostic disable-next-line: unused-local
	fallback = function(text)
		vim.api.nvim_feedkeys("gx<CR>", 'n', true)
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
	for opener, opener_fn in pairs(loaded_config.openers) do
		local res = opener_fn(text)
		vim.pretty_print(res)
		if res ~= nil then
			system_open.fn(res)
			return
		end
	end

	loaded_config.fallback(text)
end

M.open_cword = function()
	M.open(vim.fn.expand('<cWORD>'))
end

return M
