# open.nvim
Open the current word (or other text) with custom openers.

E.g: Open GitHub shorthand `"ofirgall/open.nvim"` at your default browser.

## Installation
```lua
use 'ofirgall/open.nvim'
```

## Usage
```lua
-- Leave empty for default values
require('open').setup {
}


require('open').setup {
     -- all the default openers, see below how to add/remove
    openers = require('open.default_openers'),
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

### Add a custom opener
Please share awesome custom openers with PR.
```lua
local openers = require('open.default_openers')
openers.my_custom_opener = function(text)
    -- Process text here

    -- Return uri to open
    return "www.example.com"
end

require('open').setup {
    openers = openers
}
```

### Remove an existing opener
```lua
local openers = require('open.default_openers')
openers.url = nil -- Remove from dict

require('open').setup {
    openers = openers
}
```
