# open.nvim
Open the current word (or other text) with custom openers.

E.g: Open GitHub shorthand `"ofirgall/open.nvim"` at your default browser.

## Installation
```lua
use { 'ofirgall/open.nvim', requires = 'nvim-lua/plenary.nvim' }
```

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

# Credits
* [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) for the system opener module.
