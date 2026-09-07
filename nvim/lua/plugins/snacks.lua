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
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓██████████████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓██████▓▒░   ░▒▓██▓▒░  ░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
	]],
  [[
 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██ 
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░   
         ░    ░  ░    ░ ░        ░   ░         ░   
                                ░
    ]],
  [[
  _   _   U _____ u U  ___ u__     __             __  __  
 | \ |"|  \| ___"|/  \/"_ \/\ \   /"/u  ___     U|' \/ '|u
<|  \| |>  |  _|"    | | | | \ \ / //  |_"_|    \| |\/| |/
U| |\  |u  | |___.-,_| |_| | /\ V /_,-. | |      | |  | | 
 |_| \_|   |_____|\_)-\___/ U  \_/-(_/U/| |\u    |_|  |_| 
 ||   \\,-.<<   >>     \\     //   .-,_|___|_,-.<<,-,,-.  
 (_")  (_/(__) (__)   (__)   (__)   \_)-' '-(_/  (./  \.)
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
<-. (`-')_  (`-')  _                 (`-')  _     <-. (`-')  
   \( OO) ) ( OO).-/     .->        _(OO ) (_)       \(OO )_ 
,--./ ,--/ (,------.(`-')----. ,--.(_/,-.\ ,-(`-'),--./  ,-.)
|   \ |  |  |  .---'( OO).-.  '\   \ / (_/ | ( OO)|   `.'   |
|  . '|  |)(|  '--. ( _) | |  | \   /   /  |  |  )|  |'.'|  |
|  |\    |  |  .--'  \|  |)|  |_ \     /_)(|  |_/ |  |   |  |
|  | \   |  |  `---.  '  '-'  '\-'\   /    |  |'->|  |   |  |
`--'  `--'  `------'   `-----'     `-'     `--'   `--'   `--'
    ]],
  [[
 )\  )\   )\.---.     .-./(       .-.  .'(   )\   )\  
(  \, /  (   ,-._(  ,'     )  ,'  /  ) \  ) (  ',/ /  
 ) \ (    \  '-,   (  .-, (  (  ) | (  ) (   )    (   
( ( \ \    ) ,-`    ) '._\ )  ) './ /  \  ) (  \(\ \  
 `.)/  )  (  ``-.  (  ,   (  (  ,  (    ) \  `.) /  ) 
    '.(    )..-.(   )/ ._.'   )/..'      )/      '.(  
    ]],
}

-- Helper function to get the correct binary path based on OS
local function get_bin(name)
  local os = vim.uv.os_uname().sysname:lower()
  local subfolder = (os == "darwin") and "macos" or "linux"
  local config_path = vim.fn.stdpath("config")
  local local_path = config_path .. "/bin/" .. subfolder .. "/" .. name
  if vim.fn.filereadable(local_path) == 1 then
    return local_path
  end
  return config_path .. "/bin/common/" .. name
end

-- Prevent unbounded memory leak in snacks.nvim streaming terminal jobs
do
  local ok, Job = pcall(require, "snacks.util.job")
  if ok and Job and Job.new then
    local orig_new = Job.new
    Job.new = function(buf, cmd, opts)
      local job = orig_new(buf, cmd, opts)
      if job.opts.term then
        -- Clear callbacks before job:start() so Neovim pipes directly to PTY with 0 Lua memory allocations
        job.opts.on_stdout = nil
        job.opts.on_stderr = nil
        function job:on_output() end
        if buf and vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].scrollback = 1
        end
      end
      return job
    end
  end
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    -- disable Defaults
    { "<leader>fb", false }, -- Buffers
    { "<leader>fB", false }, -- Buffers (all)
    { "<leader>fc", false }, -- Find Config File
    { "<leader>fe", false }, -- Explorer Snacks (root dir)
    { "<leader>fE", false }, -- Explorer Snacks (cwd)
    { "<leader>ff", false }, -- Find Files (Root Dir)
    { "<leader>fF", false }, -- Find Files (cwd)
    { "<leader>fg", false }, -- Find Files (git-files)
    { "<leader>fn", false }, -- New File
    { "<leader>fp", false }, -- Projects
    { "<leader>fr", false }, -- Recent
    { "<leader>fR", false }, -- Recent (cwd)
    { "<leader>ft", false }, -- Terminal (Root Dir)
    { "<leader>fT", false }, -- Terminal (cwd)

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
    styles = {
      enabled = true,
      dashboard = {
        width = 0,
        height = 0,
        border = "none",
      },
    },
    toggle = { enabled = true },

    dashboard = {
      enabled = true,
      row = 0, -- dashboard position at the top
      col = 0, -- dashboard position at the left
      pane_gap = 0, -- empty columns between vertical panes
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
      },
      -- item field formatters
      formats = {
        footer = { "%s", align = "center" },
        header = { "%s", align = "center" },
      },
      sections = {
        function()
          local stats = require("lazy.stats").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          local extra = string.format(
            " Neovim loaded %d/%d plugins in %.2fms\n\n github.com/Cyclone1070\n linkedin.com/in/huy-hoang-mai/",
            stats.loaded,
            stats.count,
            ms
          )
          local b64 = vim.base64.encode(extra)
          local logos_b64 = vim.base64.encode(vim.json.encode(logos))
          local cmd = string.format("python3 %s --logos-b64 %s --extra-b64 %s", get_bin("tte_slideshow.py"), logos_b64, b64)
          local win_h = vim.o.lines - vim.o.cmdheight
          local win_w = vim.o.columns
          return {
            section = "terminal",
            cmd = cmd,
            height = win_h,
            width = win_w,
            padding = 0,
            ttl = 0,
          }
        end,
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
            list = {
              keys = {
                ["<CR>"] = { "edit_vsplit" },
                ["l"] = { "edit_vsplit" },
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
                ["<C-p>"] = { "toggle_preview", mode = "i" },
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
