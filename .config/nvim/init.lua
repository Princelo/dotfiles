local vimrc = "~/.vimrc"
vim.cmd.source(vimrc)
local nmap = function(keys, func, desc)
    if desc then
        desc = "LSP: " .. desc
    end
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
end
local vmap = function(keys, func, desc)
    if desc then
        desc = "LSP: " .. desc
    end
    vim.keymap.set("v", keys, func, { buffer = bufnr, desc = desc })
end

--###### GITBLAME #########
require('gitsigns').setup()

--###### LSP #########
--require'lspconfig'.pyright.setup{}
require("mason").setup()
require("mason-lspconfig").setup()
--require'lspconfig'.pylsp.setup{}
vim.keymap.set("n", "[g", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]g", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "]ag", vim.diagnostic.setqflist)
vim.keymap.set("n", "[ag", vim.diagnostic.setqflist)
vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = 0 })
nmap("K", vim.lsp.buf.hover, "Hover Documentation")
nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
nmap("gD", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", "Open Definition in Vertical Split")
nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
nmap("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
nmap("<leader>Ic", vim.lsp.buf.incoming_calls, "[I]ncoming [C]alls")
nmap("<leader>Oc", vim.lsp.buf.outgoing_calls, "[O]utgoing [C]alls")
nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
nmap("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
-- Lesser used LSP functionality
nmap("<leader>wA", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
nmap("<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, "[W]orkspace [L]ist Folders")

nmap("<leader>l", vim.lsp.buf.format, "Format Buffer")
vmap("<leader>l", vim.lsp.buf.format, "Format Buffer")
local diagnostics_active = true
vim.keymap.set('n', '<leader>dn', function()
    diagnostics_active = not diagnostics_active
    if diagnostics_active then
        vim.diagnostic.show()
    else
        vim.diagnostic.hide()
    end
end)
-- vim.diagnostic.config({ virtual_text = true })
-- vim.diagnostic.open_float

--###### CMP #########
local cmp = require 'cmp'
cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            --require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
        end,
    },
    window = {
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<Tab>'] = cmp.mapping.confirm({ select = true }),
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        --{ name = 'luasnip' },
    }, {
        { name = 'buffer' },
    })
})

-- Set up lspconfig.
local border = {
      {"╭", "FloatBorder"},
      {"─", "FloatBorder"},
      {"╮", "FloatBorder"},
      {"│", "FloatBorder"},
      {"╯", "FloatBorder"},
      {"─", "FloatBorder"},
      {"╰", "FloatBorder"},
      {"│", "FloatBorder"},
}

-- To instead override globally
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end


local capabilities = require('cmp_nvim_lsp').default_capabilities()
-- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
--require('lspconfig').pyright.setup {
--  capabilities = capabilities
--}
require('lspconfig').pylsp.setup {
    capabilities = capabilities
}
require('lspconfig').ts_ls.setup {
    capabilities = capabilities
}
require('lspconfig').clangd.setup {
    capabilities = capabilities
}
require('lspconfig').gopls.setup {
    capabilities = capabilities
}
require('lspconfig').html.setup {
    capabilities = capabilities
}
require('lspconfig').jsonls.setup {
    capabilities = capabilities
}
require('lspconfig').cssls.setup {
    capabilities = capabilities
}
require('lspconfig').lua_ls.setup {
    capabilities = capabilities
}
require('lspconfig').lemminx.setup {
    capabilities = capabilities
}
require('lspconfig').yamlls.setup {
    capabilities = capabilities
}
require('lspconfig')['kotlin_language_server'].setup {
    capabilities = capabilities
}
require('lspconfig').intelephense.setup {
    capabilities = capabilities
}

require('nvim-ts-autotag').setup({
    opts = {
        -- Defaults
        enable_close = true,      -- Auto close tags
        enable_rename = true,     -- Auto rename pairs of tags
        enable_close_on_slash = false -- Auto close on trailing </
    },
    -- Also override individual filetype configs, these take priority.
    -- Empty by default, useful if one of the "opts" global settings
    -- doesn't work well in a specific filetype
    per_filetype = {
        --["html"] = {
        --  enable_close = false
        --}
    }
})
require("nvim-autopairs").setup {}

vim.o.foldcolumn = '0'
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    local suffix = (' 󰁂 %d '):format(endLnum - lnum)
    local sufWidth = vim.fn.strdisplaywidth(suffix)
    local targetWidth = width - sufWidth
    local curWidth = 0
    for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
        else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, {chunkText, hlGroup})
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, {suffix, 'MoreMsg'})
    return newVirtText
end

require('ufo').setup({
    fold_virt_text_handler = handler
})


--###### OUTLINE #########
require("outline").setup({})

--###### TREESITTER #########
require 'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all" (the listed parsers MUST always be installed)
    ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "java", "javascript", "php", "yaml", "xml", "html", "toml", "scala", "ruby", "python", "perl", "nginx", "mermaid", "make", "helm", "groovy", "gomod", "go", "erlang", "diff", "csv", "css", "cpp", "cmake", "c", "bash" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- List of parsers to ignore installing (or "all")
    -- ignore_install = { "javascript" },

    ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

    highlight = {
        enable = true,

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        -- disable = { "c", "rust" },
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },
}


--###### IBL #########
require("ibl").setup()


--###### TELESCOPE #########
require('telescope').setup {
    defaults = {
        preview = {
            filesize_limit = 0.5555,
        }
    },
    extensions = {
        fzf = {
            fuzzy = true,             -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
        }
    }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')
require('telescope').load_extension('dap')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, {})
vim.keymap.set('v', '<leader>f', '"sy:Telescope find_files default_text=<C-r>s<CR>', {})
vim.keymap.set('n', '<leader>s', require("telescope").extensions.live_grep_args.live_grep_args, { noremap = true })
vim.keymap.set('v', '<leader>s', '"sy:Telescope live_grep_args default_text="<C-r>s<CR>"', {})
vim.keymap.set('n', '<leader>bf', builtin.buffers, {})
vim.keymap.set('n', '<leader>t', builtin.tags, {})
vim.keymap.set('v', '<leader>t', '"ty:Telescope tags default_text=<C-r>t<CR>', {})
vim.keymap.set('n', '<leader>r', builtin.registers, {})


--###### NVIM TREE #########
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- OR setup with some options
require("nvim-tree").setup({
    filters = {
        dotfiles = false,
        exclude = { vim.fn.stdpath "config" .. "/lua/custom" },
    },
    disable_netrw = true,
    hijack_netrw = true,
    hijack_cursor = true,
    hijack_unnamed_buffer_when_opening = false,
    sync_root_with_cwd = true,
    update_focused_file = {
        enable = true,
        update_root = false,
    },
    view = {
        adaptive_size = true,
        side = "left",
        width = 30,
        preserve_window_proportions = true,
    },
    git = {
        enable = false,
        ignore = true,
    },
    filesystem_watchers = {
        enable = true,
    },
    actions = {
        open_file = {
            resize_window = true,
        },
    },
    renderer = {
        root_folder_label = false,
        highlight_git = false,
        highlight_opened_files = "none",

        indent_markers = {
            enable = false,
        },

        icons = {
            show = {
                file = true,
                folder = true,
                folder_arrow = true,
                git = false,
            },

            glyphs = {
                default = "󰈚",
                symlink = "",
                folder = {
                    default = "",
                    empty = "",
                    empty_open = "",
                    open = "",
                    symlink = "",
                    symlink_open = "",
                    arrow_open = "",
                    arrow_closed = "",
                },
                git = {
                    unstaged = "✗",
                    staged = "✓",
                    unmerged = "",
                    renamed = "➜",
                    untracked = "★",
                    deleted = "",
                    ignored = "◌",
                },
            },
        },
    },
})
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', {})

--###### NORD THEME #########
require("nord").setup({
  diff = { mode = "fg" },
  search = { theme = "vscode" },
  styles = {
    comments = { italic = false },
  }
})
vim.cmd.colorscheme("nord")
vim.opt.cursorline = true
require("visual_studio_code").setup({
    -- `dark` or `light`
    mode = "light",
})

--###### LUA LINE #########
require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        --component_separators = { left = '', right = ''},
        --section_separators = { left = '', right = ''},
        --section_separators = { left = '', right = '' },
        --component_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
            statusline = { 'NvimTree' },
            winbar = {},
            "dapui_watches", "dapui_breakpoints",
            "dapui_scopes", "dapui_console",
            "dapui_stacks", "dap-repl"
        },
        ignore_focus = {
            "dapui_watches", "dapui_breakpoints",
            "dapui_scopes", "dapui_console",
            "dapui_stacks", "dap-repl"
        },
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },
    inactive_sections = {
        --lualine_a = {},
        --lualine_b = {},
        --lualine_c = {'filename'},
        --lualine_x = {'location'},
        --lualine_y = {},
        --lualine_z = {}
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'filename' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {}
}


--###### BUFFER LINE #########
vim.opt.termguicolors = true
require("bufferline").setup({
    highlights = {
        background = {
            italic = false,
        },
        buffer_selected = {
            bold = true,
            italic = false,
        },
    },
    options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        numbers = "none", -- can be "none" | "ordinal" | "buffer_id" | "both" | function
        close_command = ':Bclose', -- can be a string | function, see "Mouse actions"
        right_mouse_command = "vert sbuffer %d", -- can be a string | function, see "Mouse actions"
        left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
        indicator = {
            icon = "▎", -- this should be omitted if indicator style is not 'icon'
            style = "icon", -- can also be 'underline'|'none',
        },
        buffer_close_icon = "󰅖",
        modified_icon = " ",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        --- name_formatter can be used to change the buffer's label in the bufferline.
        --- Please note some names can/will break the
        --- bufferline so use this at your discretion knowing that it has
        --- some limitations that will *NOT* be fixed.
        name_formatter = function(buf) -- buf contains a "name", "path" and "bufnr"
            -- remove extension from markdown files for example
            if buf.name:match "%.md" then
                return vim.fn.fnamemodify(buf.name, ":t:r")
            end
        end,
        max_name_length = 18,
        max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- whether or not tab names should be truncated
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        --diagnostics_indicator = diagnostics_indicator,
        -- NOTE: this will be called a lot so don't do any heavy processing here
        --custom_filter = custom_filter,
        offsets = {
            {
                filetype = "undotree",
                text = "Undotree",
                highlight = "PanelHeading",
                padding = 1,
            },
            {
                filetype = "NvimTree",
                text = "Explorer",
                highlight = "PanelHeading",
                padding = 1,
            },
            {
                filetype = "DiffviewFiles",
                text = "Diff View",
                highlight = "PanelHeading",
                padding = 1,
            },
            {
                filetype = "flutterToolsOutline",
                text = "Flutter Outline",
                highlight = "PanelHeading",
            },
            {
                filetype = "lazy",
                text = "Lazy",
                highlight = "PanelHeading",
                padding = 1,
            },
        },
        color_icons = true, -- whether or not to add the filetype icon highlights
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        show_tab_indicators = true,
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = "thin",
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        hover = {
            enabled = false, -- requires nvim 0.8+
            delay = 200,
            reveal = { "close" },
        },
        sort_by = "id",
    },
})

--###### NEO SCROLL #########
require('neoscroll').setup({ mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>' } })


--###### YAZI #########
vim.keymap.set("n", "<leader>yz", function()
    require("yazi").yazi()
end)

--###### DAP #########
require("nvim-dap-virtual-text").setup()
require("dapui").setup()
local dap, dapui = require("dap"), require("dapui")
dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end
vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapLogPoint", { text = ".>", texthl = "DiagnosticInfo" })

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.HINT] = '',
            [vim.diagnostic.severity.INFO] = '',
        },
        linehl = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
            [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
            [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
            [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
            [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
        },
    },
})

--local signs = { Error = " ", Warn = "", Hint = "", Info = " " }
--for type, icon in pairs(signs) do
    --local hl = "DiagnosticSign" .. type
    --vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
--end

dap.adapters.php = {
    type = "executable",
    command = "node",
    args = { vim.env.HOME .. "/.vim/pack/plugins/vscode-php-debug/out/phpDebug.js" }
}

dap.configurations.php = {
    {
        type = "php",
        request = "launch",
        name = "Listen for Xdebug",
        port = 9003
    }
}

require("dap-python").setup(vim.env.HOME .. "/.virtualenvs/debugpy/bin/python")

require("dap-vscode-js").setup({
    -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
    debugger_path = vim.env.HOME .. "/.vim/pack/plugins/vscode-js-debug",                       -- Path to vscode-js-debug installation.
    -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
    adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
    -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
    -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
    -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
})

for _, language in ipairs({ "typescript", "javascript" }) do
    require("dap").configurations[language] = {
        -- attach to a node process that has been started with
        -- `--inspect` for longrunning tasks or `--inspect-brk` for short tasks
        -- npm script -> `node --inspect-brk ./node_modules/.bin/vite dev`
        {
            -- use nvim-dap-vscode-js's pwa-node debug adapter
            type = "pwa-node",
            -- attach to an already running node process with --inspect flag
            -- default port: 9222
            request = "attach",
            -- allows us to pick the process using a picker
            processId = require 'dap.utils'.pick_process,
            -- name of the debug action you have to select for this config
            name = "Attach debugger to existing `node --inspect` process",
            -- for compiled languages like TypeScript or Svelte.js
            sourceMaps = true,
            -- resolve source maps in nested locations while ignoring node_modules
            resolveSourceMapLocations = {
                "${workspaceFolder}/**",
                "!**/node_modules/**" },
            -- path to src in vite based projects (and most other projects as well)
            cwd = "${workspaceFolder}/src",
            -- we don't want to debug code inside node_modules, so skip it!
            skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
        },
        {
            type = "pwa-chrome",
            name = "Launch Chrome to debug client",
            request = "launch",
            url = "http://localhost:5173",
            sourceMaps = true,
            protocol = "inspector",
            port = 9222,
            webRoot = "${workspaceFolder}/src",
            -- skip files from vite's hmr
            skipFiles = { "**/node_modules/**/*", "**/@vite/*", "**/src/client/*", "**/src/*" },
        },
        -- only if language is javascript, offer this debug action
        language == "javascript" and {
            -- use nvim-dap-vscode-js's pwa-node debug adapter
            type = "pwa-node",
            -- launch a new process to attach the debugger to
            request = "launch",
            -- name of the debug action you have to select for this config
            name = "Launch file in new node process",
            -- launch current file
            program = "${file}",
            cwd = "${workspaceFolder}",
        } or nil,
    }
end

require("dap").adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
        command = "node",
        -- 💀 Make sure to update this path to point to your installation
        args = {
            vim.env.HOME .. "/.vim/pack/plugins/js-debug/src/dapDebugServer.js",
            "${port}",
        },
    },
}

require('dap-go').setup()

--###### QUICK SCOPE ########
require'eyeliner'.setup {
  highlight_on_key = true,
  dim = true,
}
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'visual_studio_code',
  callback = function()
    vim.api.nvim_set_hl(0, 'EyelinerDimmed', { fg = '#969696' })
    vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = vim.api.nvim_get_hl_by_name('Constant', true).foreground, bold = true, underline = true })
    vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = vim.api.nvim_get_hl_by_name('Define', true).foreground, underline = true })
  end,
})
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'nord',
  callback = function()
    vim.api.nvim_set_hl(0, 'EyelinerDimmed', { fg = vim.api.nvim_get_hl_by_name('Comment', true).foreground })
    vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = vim.api.nvim_get_hl_by_name('Constant', true).foreground, bold = true, underline = true })
    vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = vim.api.nvim_get_hl_by_name('Define', true).foreground, underline = true })
  end,
})

vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = vim.api.nvim_get_hl_by_name('Constant', true).foreground, bold = true, underline = true })
vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = vim.api.nvim_get_hl_by_name('Define', true).foreground, underline = true })

vim.env.PATH = '/opt/homebrew/bin:' .. vim.env.HOME .. '/go/bin:/usr/local/go/bin:/usr/local/bin:' .. vim.env.PATH
