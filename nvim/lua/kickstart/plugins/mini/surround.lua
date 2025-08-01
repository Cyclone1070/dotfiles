return {
	"echasnovski/mini.surround",
	config = function()
		require("mini.surround").setup()
		vim.keymap.set("n", "s", "<Nop>")
	end,
}
