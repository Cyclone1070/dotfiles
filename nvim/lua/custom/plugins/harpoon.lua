return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")

		-- REQUIRED
		harpoon:setup()
		-- REQUIRED

		vim.keymap.set("n", "Ha", function()
			harpoon:list():add()
		end, { desc = "Add file to Harpoon list" })
		vim.keymap.set("n", "Hl", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Toggle Harpoon quick menu" })

		-- Jump to 1-5 files in Harpoon list
		vim.keymap.set("n", "H1", function()
			harpoon:list():select(1)
		end, { desc = "Go to Harpoon file 1" })
		vim.keymap.set("n", "H2", function()
			harpoon:list():select(2)
		end, { desc = "Go to Harpoon file 2" })
		vim.keymap.set("n", "H3", function()
			harpoon:list():select(3)
		end, { desc = "Go to Harpoon file 3" })
		vim.keymap.set("n", "H4", function()
			harpoon:list():select(4)
		end, { desc = "Go to Harpoon file 4" })
		vim.keymap.set("n", "H5", function()
			harpoon:list():select(5)
		end, { desc = "Go to Harpoon file 5" })

		-- Remove current file from Harpoon list
		vim.keymap.set("n", "Hx", function()
			harpoon:list():remove()
		end, { desc = "Remove current file from Harpoon list" })

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "Hp", function()
			harpoon:list():prev()
		end, { desc = "Go to previous Harpoon file" })
		vim.keymap.set("n", "Hn", function()
			harpoon:list():next()
		end, { desc = "Go to next Harpoon file" })
	end,
}
