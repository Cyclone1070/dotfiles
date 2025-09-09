-- Add this line somewhere at the top of your init.lua or config file
math.randomseed(os.time()) -- Ensure random numbers are different on each startup

-- Define your logos outside the plugin configuration
local logos = {
	[[
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░   ░░░  ░░        ░░░      ░░░  ░░░░  ░░        ░░  ░░░░  ░
▒    ▒▒  ▒▒  ▒▒▒▒▒▒▒▒  ▒▒▒▒  ▒▒  ▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒   ▒▒   ▒
▓  ▓  ▓  ▓▓      ▓▓▓▓  ▓▓▓▓  ▓▓▓  ▓▓  ▓▓▓▓▓▓  ▓▓▓▓▓        ▓
█  ██    ██  ████████  ████  ████    ███████  █████  █  █  █
█  ███   ██        ███      ██████  █████        ██  ████  █
████████████████████████████████████████████████████████████
	]],
	[[                                                    
 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ 
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ 
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ 
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ 
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ 
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ 
	]],
	[[
                                                                     
       ████ ██████           █████      ██                     
      ███████████             █████                             
      █████████ ███████████████████ ███   ███████████   
     █████████  ███    █████████████ █████ ██████████████   
    █████████ ██████████ █████████ █████ █████ ████ █████   
  ███████████ ███    ███ █████████ █████ █████ ████ █████  
 ██████  █████████████████████ ████ █████ █████ ████ ██████ 
 	]],
	[[
@@@  @@@  @@@@@@@@   @@@@@@   @@@  @@@  @@@  @@@@@@@@@@ 
@@@@ @@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@@@@
@@!@!@@@  @@!       @@!  @@@  @@!  @@@  @@!  @@! @@! @@!
!@!!@!@!  !@!       !@!  @!@  !@!  @!@  !@!  !@! !@! !@!
@!@ !!@!  @!!!:!    @!@  !@!  @!@  !@!  !!@  @!! !!@ @!@
!@!  !!!  !!!!!:    !@!  !!!  !@!  !!!  !!!  !@!   ! !@!
!!:  !!!  !!:       !!:  !!!  :!:  !!:  !!:  !!:     !!:
:!:  !:!  :!:       :!:  !:!   ::!!:!   :!:  :!:     :!:
 ::   ::   :: ::::  ::::: ::    ::::     ::  :::     :: 
::    :   : :: ::    : :  :      :      :     :      :  
	]],
	[[
                                                                                         .         .           
b.             8 8 8888888888       ,o888888o.  `8.`888b           ,8'  8 8888          ,8.       ,8.          
888o.          8 8 8888          . 8888     `88. `8.`888b         ,8'   8 8888         ,888.     ,888.         
Y88888o.       8 8 8888         ,8 8888       `8b `8.`888b       ,8'    8 8888        .`8888.   .`8888.        
.`Y888888o.    8 8 8888         88 8888        `8b `8.`888b     ,8'     8 8888       ,8.`8888. ,8.`8888.       
8o. `Y888888o. 8 8 888888888888 88 8888         88  `8.`888b   ,8'      8 8888      ,8'8.`8888,8^8.`8888.      
8`Y8o. `Y88888o8 8 8888         88 8888         88   `8.`888b ,8'       8 8888     ,8' `8.`8888' `8.`8888.     
8   `Y8o. `Y8888 8 8888         88 8888        ,8P    `8.`888b8'        8 8888    ,8'   `8.`88'   `8.`8888.    
8      `Y8o. `Y8 8 8888         `8 8888       ,8P      `8.`888'         8 8888   ,8'     `8.`'     `8.`8888.   
8         `Y8o.` 8 8888          ` 8888     ,88'        `8.`8'          8 8888  ,8'       `8        `8.`8888.  
8            `Yo 8 888888888888     `8888888P'           `8.`           8 8888 ,8'         `         `8.`8888. 
	]],
	[[
        _  _                              _            
       | \| |    ___     ___    __ __    (_)    _ __   
       | .` |   / -_)   / _ \   \ V /    | |   | '  \  
       |_|\_|   \___|   \___/   _\_/_   _|_|_  |_|_|_| 
      _|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
      "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 
	]],
	[[
     .-') _   ('-.                     (`-.           _   .-')    
    ( OO ) )_(  OO)                  _(OO  )_        ( '.( OO )_  
,--./ ,--,'(,------. .-'),-----. ,--(_/   ,. \ ,-.-') ,--.   ,--.)
|   \ |  |\ |  .---'( OO'  .-.  '\   \   /(__/ |  |OO)|   `.'   | 
|    \|  | )|  |    /   |  | |  | \   \ /   /  |  |  \|         | 
|  .     |/(|  '--. \_) |  |\|  |  \   '   /,  |  |(_/|  |'.'|  | 
|  |\    |  |  .--'   \ |  | |  |   \     /__),|  |_.'|  |   |  | 
|  | \   |  |  `---.   `'  '-'  '    \   /   (_|  |   |  |   |  | 
`--'  `--'  `------'     `-----'      `-'      `--'   `--'   `--' 
	]],
	[[
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓██████████████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓██████▓▒░   ░▒▓██▓▒░  ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
	]],
	[[
 .-----------------. .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| | ____  _____  | || |  _________   | || |     ____     | || | ____   ____  | || |     _____    | || | ____    ____ | |
| ||_   \|_   _| | || | |_   ___  |  | || |   .'    `.   | || ||_  _| |_  _| | || |    |_   _|   | || ||_   \  /   _|| |
| |  |   \ | |   | || |   | |_  \_|  | || |  /  .--.  \  | || |  \ \   / /   | || |      | |     | || |  |   \/   |  | |
| |  | |\ \| |   | || |   |  _|  _   | || |  | |    | |  | || |   \ \ / /    | || |      | |     | || |  | |\  /| |  | |
| | _| |_\   |_  | || |  _| |___/ |  | || |  \  `--'  /  | || |    \ ' /     | || |     _| |_    | || | _| |_\/_| |_ | |
| ||_____|\____| | || | |_________|  | || |   `.____.'   | || |     \_/      | || |    |_____|   | || ||_____||_____|| |
| |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
	]],
	[[
 /$$   /$$                                /$$              
| $$$ | $$                               |__/              
| $$$$| $$  /$$$$$$   /$$$$$$  /$$    /$$ /$$ /$$$$$$/$$$$ 
| $$ $$ $$ /$$__  $$ /$$__  $$|  $$  /$$/| $$| $$_  $$_  $$
| $$  $$$$| $$$$$$$$| $$  \ $$ \  $$/$$/ | $$| $$ \ $$ \ $$
| $$\  $$$| $$_____/| $$  | $$  \  $$$/  | $$| $$ | $$ | $$
| $$ \  $$|  $$$$$$$|  $$$$$$/   \  $/   | $$| $$ | $$ | $$
|__/  \__/ \_______/ \______/     \_/    |__/|__/ |__/ |__/
	]],
	[[
      ___           ___           ___           ___                       ___     
     /\__\         /\  \         /\  \         /\__\          ___        /\__\    
    /::|  |       /::\  \       /::\  \       /:/  /         /\  \      /::|  |   
   /:|:|  |      /:/\:\  \     /:/\:\  \     /:/  /          \:\  \    /:|:|  |   
  /:/|:|  |__   /::\~\:\  \   /:/  \:\  \   /:/__/  ___      /::\__\  /:/|:|__|__ 
 /:/ |:| /\__\ /:/\:\ \:\__\ /:/__/ \:\__\  |:|  | /\__\  __/:/\/__/ /:/ |::::\__\
 \/__|:|/:/  / \:\~\:\ \/__/ \:\  \ /:/  /  |:|  |/:/  / /\/:/  /    \/__/~~/:/  /
     |:/:/  /   \:\ \:\__\    \:\  /:/  /   |:|__/:/  /  \::/__/           /:/  / 
     |::/  /     \:\ \/__/     \:\/:/  /     \::::/__/    \:\__\          /:/  /  
     /:/  /       \:\__\        \::/  /       ~~~~         \/__/         /:/  /   
     \/__/         \/__/         \/__/                                   \/__/    
	]],
}

-- Choose a logo once when Neovim starts
local chosen_dashboard_logo = logos[math.random(1, #logos)]
-- Calculate terminal section size based on logo line count and total screen lines
local logo_line_count = 0
for _ in string.gmatch(chosen_dashboard_logo, "([^\n]*)") do
	logo_line_count = logo_line_count + 1
end
local terminal_section_height = vim.opt.lines:get() - logo_line_count + 4 -- Total screen lines
local dashboard_width = vim.opt.columns:get()
if dashboard_width > 120 then
	dashboard_width = 120
end
-- Randomly choose a terminal command
local terminal_commands = {
	"~/.config/nvim/fire.pl",
	"~/.config/nvim/cxxmatrix --preserve-background --frame-rate 10 -s rain-forever",
	"~/.config/nvim/cxxmatrix --preserve-background --frame-rate 10 -s conway -s loop",
	"~/.config/nvim/asciiquarium -t",
	"pipes.sh -p 7 -t 1 -t 3 -f 100 -r 3000",
	"cbonsai -t 0.01 -l -L 40",
	"TERM=screen-256color lavat",
	"TERM=screen-256color ~/.config/nvim/terminal_rain_lightning.py",
}
local chosen_terminal_command
-- match fire to fade logo
if chosen_dashboard_logo == logos[1] then
	chosen_terminal_command = terminal_commands[1]
else
	chosen_terminal_command = terminal_commands[math.random(1, #terminal_commands)]
end
if chosen_terminal_command == terminal_commands[1] then
	chosen_dashboard_logo = logos[1]
end
-- adjust terminal section height for specific commands if needed
if chosen_terminal_command:find("~/.config/nvim/fire.pl") then
	terminal_section_height = 22
end
-- random color for lavat
if chosen_terminal_command:find("lavat") then
	-- red, blue, yellow, green, cyan, magenta, whit
	local colors = { "red", "blue", "yellow", "green", "cyan", "magenta", "white" }
	chosen_terminal_command = chosen_terminal_command .. " -c " .. colors[math.random(1, #colors)]
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	keys = {
		-- lsp keymaps
		{
			"glr",
			function()
				Snacks.picker.lsp_references()
			end,
			desc = "[G]oto [L]SP [R]eferences",
			nowait = true,
		},
		{
			"gli",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "[G]oto [L]SP [I]mplementation",
		},
		{
			"gld",
			function()
				Snacks.picker.lsp_declarations()
			end,
			desc = "[G]oto [L]SP [D]eclarations",
		},
		{
			"glt",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "[G]oto [L]SP [T]ype Definition",
		},
		-- picker keymaps
		{
			"<leader><leader>",
			function()
				Snacks.explorer()
			end,
			desc = "Snacks Explorer",
		},
		{
			"<leader>sb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Snacks Buffers",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.grep()
			end,
			desc = "Snacks Grep [/]",
		},
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Snacks Diagnostics",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Snacks Help",
		},
		{
			"<leader>sH",
			function()
				Snacks.picker.highlights()
			end,
			desc = "Highlights",
		},
		{
			"<leader>sn",
			function()
				Snacks.explorer({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Snacks Neovim Config",
		},
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Git Branches",
		},
		{
			"<leader>gl",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git Log",
		},
		{
			"<leader>gL",
			function()
				Snacks.picker.git_log_line()
			end,
			desc = "Git Log Line",
		},
		{
			"<leader>gs",
			function()
				Snacks.picker.git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>gS",
			function()
				Snacks.picker.git_stash()
			end,
			desc = "Git Stash",
		},
		{
			"<leader>gd",
			function()
				Snacks.picker.git_diff()
			end,
			desc = "Git Diff (Hunks)",
		},
		-- dim keymaps
		{
			"<leader>dd",
			function()
				if Snacks.dim.enabled then
					Snacks.dim.disable()
				else
					Snacks.dim.enable()
				end
			end,
			desc = "Toggle Dim",
		},
		-- snacks scope jump
		{
			"gs",
			function()
				Snacks.scope.jump()
			end,
			desc = "Snacks Scope Jump",
		},
	},
	opts = {
		dim = { enabled = true },
		indent = { enabled = true },
		explorer = { enabled = true, replace_netrw = true },
		image = { enabled = true },
		input = { enabled = true },
		scope = { enabled = true },
		animate = { enabled = true },
		util = { enabled = true },
		styles = { enabled = true },
		toggle = { enabled = true },

		dashboard = {
			enabled = true,
			width = dashboard_width,
			row = nil, -- dashboard position. nil for center
			col = nil, -- dashboard position. nil for center
			pane_gap = 4, -- empty columns between vertical panes
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
			-- These settings are used by some built-in sections
			preset = {
				-- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
				---@type fun(cmd:string, opts:table)|nil
				pick = nil,
				-- Used by the `keys` section to show keymaps.
				-- Set your custom keymaps here.
				-- When using a function, the `items` argument are the default keymaps.
				keys = {
					{
						icon = " ",
						key = "n",
						desc = "Neovim Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						hidden = true,
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session", hidden = true },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa", hidden = true },
				},
				-- Used by the `header` section
				header = chosen_dashboard_logo,
			},
			-- item field formatters
			formats = {
				footer = { "%s", align = "center" },
				header = { "%s", align = "center" },
			},
			sections = {
				{ section = "header", padding = 1 },
				{
					section = "terminal",
					cmd = chosen_terminal_command,
					height = terminal_section_height,
					padding = 1,
					ttl = 5 * 60,
				},
				{ section = "startup", padding = 1 },
				{ section = "keys" },
			},
		},
		scroll = {
			animate = {
				duration = { step = 15, total = 100 },
			},
		},
		picker = {
			actions = {
				smart_confirm = function(picker)
					-- We get the item safely here. This context is reliable.
					local item = picker:current({ resolve = true })
					if not item then
						return
					end

					if item.dir == nil then
						picker:action("confirm")
					elseif item.dir then
						picker:action("confirm")
					else
						-- For a file, perform the "jump" action.
						picker:action("jump")
					end
				end,
				smart_esc = function(picker)
					picker:action("focus_list")
					if picker.finder.filter.pattern ~= "" then
						picker:action("list_top")
					end
				end,
				smart_vsplit = function(picker)
					local item = picker:current({ resolve = true })
					if not item then
						return
					end
					if item.dir then
						picker:action("confirm")
					else
						vim.cmd("vsplit " .. item.file)
						picker:close()
					end
				end,
				smart_hsplit = function(picker)
					local item = picker:current({ resolve = true })
					if not item then
						return
					end
					if item.dir then
						picker:action("confirm")
					else
						vim.cmd("split " .. item.file)
						picker:close()
					end
				end,
			},
			win = {
				input = {
					keys = {
						["<Esc>"] = { "smart_esc", mode = "i" },
						["<CR>"] = { "smart_confirm", mode = "i" },
						["<C-v>"] = { "smart_vsplit", mode = "i" },
						["<C-s>"] = { "smart_hsplit", mode = "i" },
					},
				},
				list = {
					keys = {
						["v"] = "smart_vsplit",
						["s"] = "smart_hsplit",
						["l"] = "smart_confirm",
						["<CR>"] = "smart_confirm",
					},
				},
			},

			sources = {
				help = {
					win = {
						input = {
							keys = {
								["<CR>"] = { "edit_vsplit", mode = "i" },
							},
						},
					},
				},
				buffers = {
					focus = "list",
					win = {
						list = {
							keys = {
								["x"] = "bufdelete",
							},
						},
					},
				},
				explorer = {
					focus = "input",
					tree = false,
					matcher = {
						fuzzy = true,
						filename_bonus = false,
					},
					sort = {
						-- default sort is by score, text length and index
						fields = { "score:desc", "#text", "idx" },
					},
					layout = {
						preview = true,
						layout = {
							box = "horizontal",
							backdrop = false,
							width = 0.8,
							height = 0.9,
							border = "none",
							{
								box = "vertical",
								{
									win = "input",
									height = 1,
									border = "rounded",
									title = "{title} {live} {flags}",
									title_pos = "center",
								},
								{ win = "list", title = " Results ", title_pos = "center", border = "rounded" },
							},
							{
								win = "preview",
								title = "{preview:Preview}",
								width = 0.45,
								border = "rounded",
								title_pos = "center",
							},
						},
					},
					follow_file = true,
					-- close on select
					auto_close = true,
					jump = { close = true },
					-- keymap for the explorer picker
					actions = {
						explorer_focus_and_clear_input = function(picker)
							local opts = picker.init_opts
							picker:close()
							Snacks.explorer(opts)
						end,
						explorer_smart_confirm = function(picker)
							-- We get the item safely here. This context is reliable.
							local item = picker:current({ resolve = true })
							if not item then
								return
							end

							if item.dir then
								picker:action("confirm")
							else
								-- For a file, perform the "jump" action.
								picker:action("jump")
							end
						end,
					},
					win = {
						-- Add the explorer actions to the input window so they work while searching
						input = {
							keys = {
								["<CR>"] = { "explorer_smart_confirm", mode = "i" },
								["<C-h>"] = { "toggle_hidden", mode = "i" },
							},
						},
						list = {
							keys = {
								["c"] = "explorer_add",
								["a"] = "explorer_focus_and_clear_input",
								["l"] = "explorer_smart_confirm",
								["<CR>"] = "explorer_smart_confirm",
							},
						},
					},
				},
			},
		},
	},
}
