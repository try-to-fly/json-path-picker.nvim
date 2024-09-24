# JSON Path Picker for Neovim

JSON Path Picker is a Neovim plugin that allows users to easily navigate and copy content from specific paths in JSON files.
![json-path](https://github.com/user-attachments/assets/5aa60547-1956-458e-9787-d66e93196ca7)

## Features

- Quick navigation in JSON files
- Select JSON paths using a Telescope interface
- Preview JSON content for selected paths
- One-click copy of formatted JSON to clipboard

## Installation

Install this plugin using your preferred plugin manager. For example, with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
return {
  'try-to-fly/json-path-picker.nvim',
    config = function()
      vim.api.nvim_set_keymap(
        "n",
        "<leader>jp",
        [[<cmd>lua require('json_path_picker').pick_json_path()<CR>]],
        { noremap = true, silent = true }
      )
    end
}
```

## Configuration

Add the following key mapping to your Neovim configuration:

```lua
vim.api.nvim_set_keymap(
  "n",
  "<leader>jp",
  [[<cmd>lua require('json_path_picker').pick_json_path()<CR>]],
  { noremap = true, silent = true }
)
```

You can change `<leader>jp` to any other key combination as needed.

## Usage

1. Open a JSON file.
2. Press the configured shortcut (default is `<leader>jp`).
3. Enter the JSON path you want to navigate to.
4. Use the Telescope interface to browse and select paths.
5. Press Enter to copy the JSON content of the selected path to the clipboard.

## Path Syntax

- Use dot notation (`.`) to separate object keys.
- Use square brackets and index (`[0]`) to access array elements.

For example: `data.users[0].name`

## Contributing

Issues and pull requests are welcome!

## License

MIT

This README provides a basic introduction to the plugin, installation instructions, configuration method, usage instructions, and other useful information. You can modify or expand it as needed, for example by adding more detailed examples, FAQs, or screenshots.
