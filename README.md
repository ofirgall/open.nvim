# open.nvim
Open the current word (or other text) with custom openers, extensible.

E.g: Open GitHub shorthand `"ofirgall/open.nvim"` at your default browser.

## Installation
```lua
use { 'ofirgall/open.nvim', requires = 'nvim-lua/plenary.nvim' }
```

You can install `vim.ui.select` wrapper to change the ui for selecting multiple results:
* [stevearc/dressing.nvim](https://github.com/stevearc/dressing.nvim)
* [nvim-telescope/telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)

## Usage
```lua
-- Leave empty for default values
require('open').setup {
}

require('open').setup {
     -- List of disabled openers, 'github' for example see `:help open.default_openers`
     disabled_openers = {
     }
     -- fallback function if no opener succeeds
    fallback = function(text)
        system_open.open(text)
    end,
    -- Override system opener, the defaults should work out of the box
    system_open = {
        cmd = "",
        args = {},
    },
}
```

By default, no keymaps are set, you have to set your own keymap:
```lua
vim.keymap.set('n', 'gx', require('open').open_cword)
```

### Register a custom opener
Please share awesome custom openers with PR.
```lua
require('open').register_opener({
    name = 'Example Opener',
    open_fn = function(text)
        return { 'www.example.org' }
    end
})
```

## List of Custom Openers
* [ofirgall/open-jira.nvim](https://github.com/ofirgall/open-jira.nvim) - Open Jira tickets shorthand.

Feel free to add your opener to the list.

# Credits
* [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) for the system opener module.
