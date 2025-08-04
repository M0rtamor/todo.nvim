# todo.nvim

Todo list manager for nvim

## Installation

`M0rtamor/todo.nvim`

Use any plugin manager to install

## Usage

Default options:

```lua
require("todo.nvim").setup({
	dirs = {
		weekly = "~/Todo/Weekly",
	},
	window = {
		border = "rounded",
		pos = "center",
		size = {
			height = "0.8",
			width = "0.8",
		},
	},
})
```

## Commands

```
:Todo weekly
```

## Example installation with Lazy

```lua
return {
	"M0rtamor/todo.nvim",
	config = function()
		require("todo").setup({
			dirs = {
				weekly = "~/Documents/Markdown/Todo/Weekly"
			},
			window = {
				size = {
					width = 0.3,
				},
			},
		})
		vim.keymap.set("n", "<leader>tw", "<cmd>Todo weekly<CR>")
	end,
}
```
