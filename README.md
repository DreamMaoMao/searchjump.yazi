# searchjump.yazi

A Yazi plugin whose behavior is consistent with flash.nvim in Neovim: from a search string it generates labels to jump to.

https://github.com/DreamMaoMao/searchjump.yazi/assets/30348075/4a00eb39-211b-47c5-8e22-644a7d7bc6b1

> [!NOTE]
> The latest main branch of Yazi is required at the moment.


## Install

### Linux

```bash
git clone https://github.com/DreamMaoMao/searchjump.yazi.git ~/.config/yazi/plugins/searchjump.yazi
```

### Windows

With `Powershell` :

```powershell
if (!(Test-Path $env:APPDATA\yazi\config\plugins\)) {mkdir $env:APPDATA\yazi\config\plugins\}
git clone https://github.com/DreamMaoMao/searchjump.yazi.git $env:APPDATA\yazi\config\plugins\searchjump.yazi
```

## Usage

Set shortcut key to toggle searchjump mode in `~/.config/yazi/keymap.toml`. For example, set `i` like this:

```toml
[[manager.prepend_keymap]]
on   = [ "i" ]
run = "plugin searchjump"
desc = "searchjump mode"
```

Or enter directory automatically when jumping onto it:

```toml
[[manager.prepend_keymap]]
on   = [ "i" ]
run = "plugin searchjump -- autocd"
desc = "searchjump mode"
```

## Setting options (in `~/.config/yazi/init.lua`)

```lua
require("searchjump"):setup({
    unmatch_fg = "#b2a496",
    match_str_fg = "#000000",
    match_str_bg = "#73AC3A",
    first_match_str_fg = "#000000",
    first_match_str_bg = "#73AC3A",
    label_fg = "#EADFC8",
    label_bg = "#BA603D",
    only_current = false,
    show_search_in_statusbar = false,
    auto_exit_when_unmatch = false,
    enable_capital_label = true,
    search_patterns = ({"hell[dk]d","%d+.1080p","第%d+集","第%d+话","%.E%d+","S%d+E%d+",})
})
```

- When you see the single character label at the right of an entry, press the corresponding key to jump to the entry.
- you can use `backspace` to delete a input character.
- you can use `enter` to jump to the first match.
- you can use `Space` to match the search_patterns you preset in config.
