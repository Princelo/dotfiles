-- Neovim single-file config
-- NOTE: Refactored for readability; behavior intended unchanged.

local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local keymap = vim.keymap.set

local kopts = { noremap = true, silent = true }

local function nmap(lhs, rhs, desc_or_opts)
	local opts = kopts
	if type(desc_or_opts) == "string" then
		opts = vim.tbl_extend("force", kopts, { desc = desc_or_opts })
	elseif type(desc_or_opts) == "table" then
		opts = vim.tbl_extend("force", kopts, desc_or_opts)
	end
	keymap("n", lhs, rhs, opts)
end

local function packadd(name)
	cmd.packadd(name)
end

-- =====================================================================
-- Editor options
-- =====================================================================

-- Locale / menus
vim.env.LANG = "en_US.UTF-8"
vim.opt.langmenu = "en"

-- Basics
vim.opt.history = 500
vim.opt.fileencodings = { "utf8", "gbk", "gb18030", "gb2312", "big5" }
vim.opt.fileformats = { "unix", "dos", "mac" }

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.path:append("**")
vim.opt.list = true
vim.opt.listchars = { tab = "→ ", nbsp = "␣", trail = "•", precedes = "«", extends = "»" }
vim.opt.scrolloff = 7
vim.opt.wildignore = { "*.o", "*~", "*.pyc", "*.class" }
if fn.has("win16") == 1 or fn.has("win32") == 1 then
	vim.opt.wildignore:append({ ".git\\*", ".hg\\*", ".svn\\*" })
else
	vim.opt.wildignore:append({ "*/.git/*", "*/.hg/*", "*/.svn/*", "*/.DS_Store" })
end
cmd("set whichwrap+=<,>,h,l")

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Performance / UX
vim.opt.lazyredraw = true
vim.opt.showmatch = true
vim.opt.matchtime = 2
vim.opt.timeoutlen = 500
vim.opt.jumpoptions = "stack"

-- Colors
vim.opt.termguicolors = true

-- Files, backups and swap
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Text, tabs and indent
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.linebreak = true
vim.opt.textwidth = 500
vim.opt.smartindent = true

-- =====================================================================
-- Autocommands
-- =====================================================================

local core_group = api.nvim_create_augroup("DotfilesCore", { clear = true })

api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	group = core_group,
	callback = function()
		cmd("silent! checktime")
	end,
})

api.nvim_create_autocmd("BufReadPost", {
	group = core_group,
	callback = function()
		local mark = api.nvim_buf_get_mark(0, '"')
		local line = mark[1]
		local col = mark[2]
		if line > 1 and line <= api.nvim_buf_line_count(0) then
			pcall(api.nvim_win_set_cursor, 0, { line, col })
		end
	end,
})

-- Mappings
keymap({ "n", "v" }, "<leader>y", '"+y', kopts)
keymap({ "n", "v" }, "<leader>p", '"+p', kopts)

keymap("v", "<leader>r", [["hy:%s/\C<C-r>h//g<left><left>]], { noremap = true })

keymap("c", "<C-A>", "<Home>", { noremap = true })
keymap("c", "<C-E>", "<End>", { noremap = true })

keymap("n", "<leader>cnt", [[:%s///gn<CR>]], kopts)

keymap("n", "q:", ":", { noremap = true })

api.nvim_create_user_command("W", function()
	cmd("w !sudo tee % > /dev/null | edit!")
end, {})

-- Window resize helpers
keymap("n", "<S-left>", ":vertical resize +3<CR>", kopts)
keymap("n", "<S-right>", ":vertical resize -3<CR>", kopts)
keymap("n", "<S-up>", ":resize -1<CR>", kopts)
keymap("n", "<S-down>", ":resize +1<CR>", kopts)

-- Window navigation (works even without tmux plugin)
keymap({ "n", "v", "o" }, "<C-h>", "<C-w>h", kopts)
keymap({ "n", "v", "o" }, "<C-j>", "<C-w>j", kopts)
keymap({ "n", "v", "o" }, "<C-k>", "<C-w>k", kopts)
keymap({ "n", "v", "o" }, "<C-l>", "<C-w>l", kopts)

-- Tmux navigator (if installed)
vim.g.tmux_navigator_no_mappings = 1
keymap("n", "<C-h>", ":<C-u>TmuxNavigateLeft<CR>", kopts)
keymap("n", "<C-j>", ":<C-u>TmuxNavigateDown<CR>", kopts)
keymap("n", "<C-k>", ":<C-u>TmuxNavigateUp<CR>", kopts)
keymap("n", "<C-l>", ":<C-u>TmuxNavigateRight<CR>", kopts)
keymap("n", "<C-\\>", ":<C-u>TmuxNavigatePrevious<CR>", kopts)

-- Switch CWD to the directory of the open buffer
keymap("n", "<leader>cd", ":cd %:p:h<CR>:pwd<CR>", kopts)
keymap("n", "<leader>tcd", ":tcd %:p:h<CR>:pwd<CR>", kopts)

-- Tabline
vim.opt.showtabline = 2

-- Buffers
keymap("n", "]b", ":bnext<CR>", kopts)
keymap("n", "[b", ":bprevious<CR>", kopts)

-- Visual selection search (* / #)
local function search_visual(backward)
	local saved_unnamed = fn.getreg('"')
	local saved_unnamed_type = fn.getregtype('"')
	local saved_z = fn.getreg("z")
	local saved_z_type = fn.getregtype("z")

	cmd("silent! normal! gv\"zy")
	local text = fn.getreg("z")

	fn.setreg('"', saved_unnamed, saved_unnamed_type)
	fn.setreg("z", saved_z, saved_z_type)

	local pattern = fn.escape(text, [=[\/.*'$^~[]]=])
	pattern = fn.substitute(pattern, [[\n$]], "", "")
	fn.setreg("/", pattern)

	if backward then
		fn.search(pattern, "b")
	else
		fn.search(pattern)
	end
end

keymap("v", "*", function()
	search_visual(false)
end, { silent = true })
keymap("v", "#", function()
	search_visual(true)
end, { silent = true })

-- Trim trailing whitespace
local function trim_trailing_whitespace()
	local cursor = api.nvim_win_get_cursor(0)
	local old_query = fn.getreg("/")
	cmd([[silent! %s/\s\+$//e]])
	api.nvim_win_set_cursor(0, cursor)
	fn.setreg("/", old_query)
end
api.nvim_create_user_command("Trim", trim_trailing_whitespace, {})

-- Compact JSON (requires jq)
keymap("n", "--", ":%!jq -c<CR>", kopts)

-- Buffer close helper (:Bclose)
cmd([[
if v:version >= 700 && !exists('loaded_bclose') && !&compatible
  let loaded_bclose = 1
  if !exists('bclose_multiple')
    let bclose_multiple = 1
  endif

  function! s:Warn(msg) abort
    echohl ErrorMsg
    echomsg a:msg
    echohl NONE
  endfunction

  function! s:Bclose(bang, buffer) abort
    if empty(a:buffer)
      let btarget = bufnr('%')
    elseif a:buffer =~# '^\d\+$'
      let btarget = bufnr(str2nr(a:buffer))
    else
      let btarget = bufnr(a:buffer)
    endif

    if btarget < 0
      call s:Warn('No matching buffer for '.a:buffer)
      return
    endif

    if empty(a:bang) && getbufvar(btarget, '&modified')
      call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
      return
    endif

    let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
    if !g:bclose_multiple && len(wnums) > 1
      call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
      return
    endif

    let wcurrent = winnr()
    for w in wnums
      execute w.'wincmd w'
      let prevbuf = bufnr('#')
      if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
        buffer #
      else
        bprevious
      endif

      if btarget == bufnr('%')
        let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
        let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
        let bjump = (bhidden + blisted + [-1])[0]
        if bjump > 0
          execute 'buffer '.bjump
        else
          execute 'enew'.a:bang
        endif
      endif
    endfor

    execute 'bdelete'.a:bang.' '.btarget
    execute wcurrent.'wincmd w'
  endfunction

  command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose(<q-bang>, <q-args>)
  cabbrev bd Bclose
endif
]])

-- Terminal
keymap("n", "<leader>tm", function()
	cmd("split")
	cmd("wincmd j")
	cmd("resize -6")
	cmd("setlocal nonumber norelativenumber")
	cmd("terminal")
	cmd("startinsert")
end, kopts)

-- Quickfix toggle
local function toggle_quickfix()
	for _, win in ipairs(fn.getwininfo()) do
		if win.quickfix == 1 then
			cmd("cclose")
			return
		end
	end
	cmd("copen")
end
keymap("n", "<leader>q", toggle_quickfix, kopts)

-- Misc
if vim.env.JAVA == "1" then
	vim.g.java = 1
end

-- =====================================================================
-- Sections
-- =====================================================================
--  - Indentation
--  - Git (gitsigns)
--  - LSP
--  - Completion (blink)
--  - UI: Folding (ufo)
--  - UI: Outline
--  - Syntax: Treesitter textobjects
--  - UI: Indent guides (ibl)
--  - Telescope
--  - File tree (nvim-tree)
--  - Theme (nord)
--  - Statusline (lualine)
--  - Bufferline
--  - Scroll (neoscroll)
--  - File manager (yazi)
--  - Debugger (dap)
--  - Quick scope (eyeliner)
--  - Search lens (hlslens)
--  - Diffview
--  - Comment
--  - Env

-- =====================================================================
-- Indentation
-- =====================================================================

local indent_group = api.nvim_create_augroup("IndentByFileType", { clear = true })

api.nvim_create_autocmd("FileType", {
	group = indent_group,
	pattern = {
		"javascript",
		"typescript",
		"jsx",
		"tsx",
		"lua",
		"html",
		"xml",
		"css",
		"json",
		"yaml",
		"toml",
		"markdown",
		"vue",
		"Dockerfile",
	},
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
	end,
})

api.nvim_create_autocmd("FileType", {
	group = indent_group,
	pattern = { "go", "sh", "make" },
	callback = function()
		vim.opt_local.expandtab = false
	end,
})

-- =====================================================================
-- Git: gitsigns
-- =====================================================================
require("gitsigns").setup()

-- =====================================================================
-- LSP
-- =====================================================================
api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.defer_fn(function()
			packadd("mason.nvim")
			packadd("nvim-lspconfig")
			packadd("mason-lspconfig.nvim")
			require("mason").setup()
			require("mason-lspconfig").setup()
	end, 100)
	end,
})

-- Diagnostics (global)
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Diagnostic: previous" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Diagnostic: next" })
keymap("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Diagnostic: quickfix" })

local diagnostics_active = true
keymap("n", "<leader>da", function()
	diagnostics_active = not diagnostics_active
	if diagnostics_active then
		vim.diagnostic.show()
	else
		vim.diagnostic.hide()
	end
end, { desc = "Diagnostic: toggle" })

keymap("n", "<leader>K", vim.diagnostic.open_float, { desc = "Diagnostic: float" })

-- LSP keymaps (buffer-local)
local lsp_keymaps_group = api.nvim_create_augroup("LspKeymaps", { clear = true })
api.nvim_create_autocmd("LspAttach", {
	group = lsp_keymaps_group,
	callback = function(args)
		local bufnr = args.buf
		local function bmap(mode, lhs, rhs, desc)
			keymap(mode, lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
		end

		bmap("i", "<C-k>", vim.lsp.buf.signature_help, "LSP: Signature Help")
		bmap("n", "K", vim.lsp.buf.hover, "LSP: Hover")
		bmap("n", "<leader>a", vim.lsp.buf.code_action, "LSP: Code Action")
		bmap("n", "gd", vim.lsp.buf.definition, "LSP: Definition")
		bmap("n", "gD", vim.lsp.buf.declaration, "LSP: Declaration")
		bmap("n", "gI", vim.lsp.buf.implementation, "LSP: Implementation")
		bmap("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
		bmap("n", "<leader>Ic", vim.lsp.buf.incoming_calls, "LSP: Incoming Calls")
		bmap("n", "<leader>Oc", vim.lsp.buf.outgoing_calls, "LSP: Outgoing Calls")
		bmap("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
		bmap("n", "<leader>D", vim.lsp.buf.type_definition, "LSP: Type Definition")
		bmap("n", "<leader>wA", vim.lsp.buf.add_workspace_folder, "LSP: Workspace Add")
		bmap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "LSP: Workspace Remove")
		bmap("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, "LSP: Workspace List")

		bmap("n", "==", function()
			vim.lsp.buf.format({ async = true })
		end, "LSP: Format")
		bmap("v", "=", function()
			vim.lsp.buf.format({ async = true })
		end, "LSP: Format")
	end,
})

-- =====================================================================
-- Completion: blink.cmp (+ autotag)
-- =====================================================================
local function blink()
	if not package.loaded["nvim-ts-autotag"] then
		packadd("nvim-ts-autotag")
		require("nvim-ts-autotag").setup({
			opts = {
				-- Defaults
				enable_close = true, -- Auto close tags
				enable_rename = false, -- Auto rename pairs of tags
				enable_close_on_slash = false, -- Auto close on trailing </
			},
			per_filetype = {
				--["html"] = {
				--  enable_close = false
				--}
			},
		})
	end
	if not package.loaded["blink.cmp"] then
		packadd("blink.cmp")
		require("blink.cmp").setup({
			keymap = { preset = "super-tab" },
		})
	end
end
api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	once = true,
	callback = blink,
	desc = "Lazy load blink.cmp on enter insert mode",
})

-- Set up lspconfig.
local border = {
	{ "╭", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╮", "FloatBorder" },
	{ "│", "FloatBorder" },
	{ "╯", "FloatBorder" },
	{ "─", "FloatBorder" },
	{ "╰", "FloatBorder" },
	{ "│", "FloatBorder" },
}

-- To instead override globally
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	if vim.g.colors_name == "nord" then
		opts = opts or {}
		opts.border = opts.border or border
	end
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

require("nvim-autopairs").setup({})

vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
local handler = function(virtText, lnum, endLnum, width, truncate)
	local newVirtText = {}
	local suffix = (" 󰁂 %d "):format(endLnum - lnum)
	local sufWidth = fn.strdisplaywidth(suffix)
	local targetWidth = width - sufWidth
	local curWidth = 0
	for _, chunk in ipairs(virtText) do
		local chunkText = chunk[1]
		local chunkWidth = fn.strdisplaywidth(chunkText)
		if targetWidth > curWidth + chunkWidth then
			table.insert(newVirtText, chunk)
		else
			chunkText = truncate(chunkText, targetWidth - curWidth)
			local hlGroup = chunk[2]
			table.insert(newVirtText, { chunkText, hlGroup })
			chunkWidth = fn.strdisplaywidth(chunkText)
			-- str width returned from truncate() may less than 2nd argument, need padding
			if curWidth + chunkWidth < targetWidth then
				suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
			end
			break
		end
		curWidth = curWidth + chunkWidth
	end
	table.insert(newVirtText, { suffix, "MoreMsg" })
	return newVirtText
end

local function ufo()
	packadd("nvim-ufo")
	require("ufo").setup({
		fold_virt_text_handler = handler,
	})
end

api.nvim_create_user_command("UFO", ufo, {})

api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = { "*" }, -- { "lua", "python", "go", "html", "js" }
	callback = ufo,
	once = true,
})

-- =====================================================================
-- UI: Outline
-- =====================================================================
local function outline()
	if package.loaded["outline"] then
		cmd("Outline")
		return
	end
	packadd("outline.nvim")
	require("outline").setup({})
	cmd("Outline")
end
nmap("<leader>o", outline)

-- =====================================================================
-- Syntax: Treesitter textobjects
-- =====================================================================
require("tree-sitter-manager").setup({})

	local function ts_select(query)
		return function()
			require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
	end
end

local function ts_move_goto(fn_name, query)
	return function()
		require("nvim-treesitter-textobjects.move")[fn_name](query, "textobjects")
	end
end

local ts_select_maps = {
	{ { "x", "o" }, "af", "@function.outer" },
	{ { "x", "o" }, "if", "@function.inner" },
	{ { "x", "o" }, "am", "@function.outer" },
	{ { "x", "o" }, "im", "@function.inner" },
	{ { "x", "o" }, "ac", "@class.outer" },
	{ { "x", "o" }, "ic", "@class.inner" },
	{ { "x", "o" }, "al", "@loop.outer" },
	{ { "x", "o" }, "il", "@loop.inner" },
	{ { "x", "o" }, "ay", "@conditional.outer" },
	{ { "x", "o" }, "iy", "@conditional.inner" },
	{ { "x", "o" }, "ak", "@comment.outer" },
	{ { "x", "o" }, "ik", "@comment.outer" },
	{ { "x", "o" }, "aa", "@parameter.outer" },
	{ { "x", "o" }, "ia", "@parameter.inner" },
}

for _, m in ipairs(ts_select_maps) do
	keymap(m[1], m[2], ts_select(m[3]))
end

local ts_move_maps = {
	{ { "n", "x", "o" }, "]a", "goto_next_start", "@parameter.inner" },
	{ { "n", "x", "o" }, "[a", "goto_previous_start", "@parameter.inner" },
	{ { "n", "x", "o" }, "]k", "goto_next_start", "@comment.outer" },
	{ { "n", "x", "o" }, "[k", "goto_previous_start", "@comment.outer" },
	{ { "n", "x", "o" }, "]f", "goto_next_start", "@function.outer" },
	{ { "n", "x", "o" }, "[f", "goto_previous_start", "@function.outer" },
}

for _, m in ipairs(ts_move_maps) do
	keymap(m[1], m[2], ts_move_goto(m[3], m[4]))
end

-- =====================================================================
-- UI: Indent guides (ibl)
-- =====================================================================
require("ibl").setup()

-- =====================================================================
-- Telescope
-- =====================================================================
local function telescope()
	if not package.loaded["telescope"] then
		packadd("telescope.nvim")
		if package.loaded["dap"] then
			packadd("telescope-dap.nvim")
		end
		packadd("telescope-fzf-native.nvim")
		--vim.cmd.packadd("telescope-live-grep-args.nvim")
		require("telescope").setup({
			defaults = {
				preview = {
					filesize_limit = 0.5555,
				},
			},
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					-- the default case_mode is "smart_case"
				},
			},
		})
	end
	-- To get fzf loaded and working with telescope, you need to call
	-- load_extension, somewhere after setup function:
	require("telescope").load_extension("fzf")
	-- require('telescope').load_extension('dap')
	if package.loaded["dap"] then
		require("telescope").load_extension("dap")
	end
	return require("telescope.builtin")
end

local function nvimtree_selected()
	local current_win = api.nvim_get_current_win()
	local current_buf = api.nvim_win_get_buf(current_win)
	local buf_name = api.nvim_buf_get_name(current_buf)
	if not string.find(buf_name, "NvimTree") then
		return false
	end
	return true
end
keymap("n", "<leader>f", function()
	local builtin = telescope()
	local node = nil
	if nvimtree_selected() and package.loaded["nvim-tree"] then
		node = require("nvim-tree.api").tree.get_node_under_cursor()
	end
	if node and node.type == "directory" then
		builtin.find_files({
			cwd = node.absolute_path,
			prompt_title = "Find Files In: " .. node.name,
		})
	else
		builtin.find_files()
	end
	end, kopts)
	keymap("v", "<leader>f", function()
		local builtin = telescope()
		cmd('normal! "sy')
	local selected_text = fn.getreg("s")
	builtin.find_files({
		default_text = selected_text,
	})
end, kopts)
keymap("n", "<leader>/", function()
	local builtin = telescope()
	if not package.loaded["telescope-live-grep-args"] then
		packadd("telescope-live-grep-args.nvim")
	end
	local node = nil
	if nvimtree_selected() and package.loaded["nvim-tree"] then
		node = require("nvim-tree.api").tree.get_node_under_cursor()
	end
	if node and node.type == "directory" then
		builtin.live_grep({
			cwd = node.absolute_path,
			prompt_title = "Find In: " .. node.name,
		})
	elseif node and node.type == "file" then
		builtin.live_grep({
			search_dirs = { node.absolute_path },
			prompt_title = "Find In: " .. node.name,
		})
	else
		builtin.live_grep()
		end
	end, kopts)
	keymap("v", "<leader>/", function()
		telescope()
		if not package.loaded["telescope-live-grep-args"] then
		packadd("telescope-live-grep-args.nvim")
	end

	cmd('normal! "sy')
	local selected_text = fn.getreg("s")
	require("telescope").extensions.live_grep_args.live_grep_args({
		default_text = selected_text,
	})
end, kopts)
keymap("n", "<leader>b", function()
	telescope().buffers()
end, kopts)
	keymap("v", "<leader>s", function()
		local builtin = telescope()
		cmd('normal! "ty')
	local selected_text = fn.getreg("t")
	builtin.lsp_document_symbols({
		default_text = selected_text,
	})
end, kopts)
keymap("v", "<leader>S", function()
	local builtin = telescope()
	cmd('normal! "ty')
	local selected_text = fn.getreg("t")
	builtin.lsp_dynamic_workspace_symbols({
		default_text = selected_text,
	})
end, kopts)
keymap("n", "<leader>r", function()
	telescope().registers()
end, kopts)
keymap("n", "gr", function()
	telescope().lsp_references()
end, kopts)
nmap("<leader>s", function()
	telescope().lsp_document_symbols()
end, "Document [S]ymbols")
nmap("<leader>S", function()
	telescope().lsp_dynamic_workspace_symbols()
end, "Workspace [S]ymbols")

-- =====================================================================
-- File tree: nvim-tree
-- =====================================================================
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- OR setup with some options
local function nvimtree()
	if not package.loaded["nvim-tree"] then
		packadd("nvim-tree.lua")
		require("nvim-tree").setup({
			filters = {
				dotfiles = false,
				exclude = { fn.stdpath("config") .. "/lua/custom" },
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
	end
end

keymap("n", "<leader>e", function()
	nvimtree()
	require("nvim-tree.api").tree.toggle()
end, kopts)

-- =====================================================================
-- Theme: nord
-- =====================================================================
require("nord").setup({
	diff = { mode = "fg" },
	search = { theme = "vscode" },
	styles = {
		comments = { italic = false },
	},
})
cmd.colorscheme("nord")
vim.opt.cursorline = true

local function safe_require(mod)
	local ok, m = pcall(require, mod)
	return ok and m or nil
end

local function safe_colorscheme(name)
	pcall(cmd.colorscheme, name)
end

api.nvim_create_user_command("Dark", function()
	safe_colorscheme("nord")
end, {})

api.nvim_create_user_command("VSCode", function()
	local vscode = safe_require("visual_studio_code")
	if vscode and vscode.setup then
		vscode.setup({ mode = "dark" })
	end
	safe_colorscheme("visual_studio_code")
end, {})

api.nvim_create_user_command("Light", function()
	local vscode = safe_require("visual_studio_code")
	if vscode and vscode.setup then
		vscode.setup({ mode = "light" })
	end
	safe_colorscheme("visual_studio_code")
end, {})

-- =====================================================================
-- Statusline: lualine
-- =====================================================================
require("lualine").setup({
	options = {
		icons_enabled = true,
		theme = "auto",
		--component_separators = { left = '', right = ''},
		--section_separators = { left = '', right = ''},
		--section_separators = { left = '', right = '' },
		--component_separators = { left = '', right = '' },
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "NvimTree", "Outline", "DiffviewFiles" },
			winbar = {},
			"dapui_watches",
			"dapui_breakpoints",
			"dapui_scopes",
			"dapui_console",
			"dapui_stacks",
			"dap-repl",
		},
		ignore_focus = {
			"dapui_watches",
			"dapui_breakpoints",
			"dapui_scopes",
			"dapui_console",
			"dapui_stacks",
			"dap-repl",
		},
		always_divide_middle = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		--lualine_a = { 'mode' },
		lualine_a = { "" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
})

-- =====================================================================
-- Bufferline
-- =====================================================================
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
		close_command = ":Bclose", -- can be a string | function, see "Mouse actions"
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
			if buf.name:match("%.md") then
				return fn.fnamemodify(buf.name, ":t:r")
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
				text = "",
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

-- =====================================================================
-- Scroll: neoscroll
-- =====================================================================
require("neoscroll").setup({ mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>" } })

-- =====================================================================
-- File manager: yazi
-- =====================================================================
keymap("n", "<leader>yz", function()
	if not package.loaded["yazi"] then
		packadd("yazi.nvim")
	end
	require("yazi").yazi()
end)

-- =====================================================================
-- Debugger: nvim-dap
-- =====================================================================
vim.diagnostic.config({
	virtual_text = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.HINT] = "",
			[vim.diagnostic.severity.INFO] = "",
		},
		linehl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
		},
	},
})
local function dap()
	if package.loaded["dap"] then
		require("dap").toggle_breakpoint()
		return
	end
	packadd("nvim-dap")
	packadd("nvim-dap-ui")
	packadd("nvim-dap-virtual-text")
	packadd("nvim-dap-python")
	packadd("nvim-dap-vscode-js")
	packadd("nvim-dap-go")
	if package.loaded["telescope"] then
		if not package.loaded["telescope-dap"] then
			packadd("telescope-dap.nvim")
		end
		require("telescope").load_extension("dap")
	end

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
	fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticWarn" })
	fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticInfo" })
	fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })
	fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticInfo" })
	fn.sign_define("DapLogPoint", { text = ".>", texthl = "DiagnosticInfo" })

	dap.adapters.php = {
		type = "executable",
		command = "node",
		args = { vim.env.HOME .. "/.local/share/nvim/site/pack/plugins/vscode-php-debug/out/phpDebug.js" },
	}

	dap.configurations.php = {
		{
			type = "php",
			request = "launch",
			name = "Listen for Xdebug",
			port = 9003,
		},
	}

	require("dap-python").setup(vim.env.HOME .. "/.virtualenvs/debugpy/bin/python")

	require("dap-vscode-js").setup({
		-- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
		debugger_path = vim.env.HOME .. "/.vim/pack/plugins/js-debug",
		-- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
		adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
		-- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
		-- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
		-- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
	})

	for _, language in ipairs({ "typescript", "javascript" }) do
		require("dap").configurations[language] = {
			{
				type = "pwa-node",
				request = "attach",
				processId = require("dap.utils").pick_process,
				name = "Attach debugger to existing `node --inspect` process",
				sourceMaps = true,
				-- resolve source maps in nested locations while ignoring node_modules
				resolveSourceMapLocations = {
					"${workspaceFolder}/**",
					"!**/node_modules/**",
				},
				-- path to src in vite based projects (and most other projects as well)
				cwd = "${workspaceFolder}/src",
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
			language == "javascript" and {
				type = "pwa-node",
				request = "launch",
				name = "Launch file in new node process",
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
			args = {
				vim.env.HOME .. "/.vim/pack/plugins/js-debug/src/dapDebugServer.js",
				"${port}",
			},
		},
	}

	require("dap-go").setup()
	require("dap").toggle_breakpoint()
end
keymap("n", "<leader>G", dap, {})

-- =====================================================================
-- Quick scope: eyeliner
-- =====================================================================
require("eyeliner").setup({
	highlight_on_key = true,
	dim = true,
})

local function eyeliner_primary_secondary()
	api.nvim_set_hl(0, "EyelinerPrimary", {
		fg = api.nvim_get_hl_by_name("Constant", true).foreground,
		bold = true,
		underline = true,
	})
	api.nvim_set_hl(0, "EyelinerSecondary", {
		fg = api.nvim_get_hl_by_name("Define", true).foreground,
		underline = true,
	})
end

local function eyeliner_all(dim_fg)
	api.nvim_set_hl(0, "EyelinerDimmed", { fg = dim_fg })
	eyeliner_primary_secondary()
end

api.nvim_create_autocmd("ColorScheme", {
	pattern = "visual_studio_code",
	callback = function()
		eyeliner_all("#969696")
	end,
})
api.nvim_create_autocmd("ColorScheme", {
	pattern = "nord",
	callback = function()
		eyeliner_all(api.nvim_get_hl_by_name("Comment", true).foreground)
	end,
})

eyeliner_primary_secondary()

-- =====================================================================
-- Search lens: hlslens
-- =====================================================================
_G.lazy_hlslens = function(ex_cmd)
	if not package.loaded["hlslens"] then
		packadd("nvim-hlslens")
		require("hlslens").setup()
	end
	cmd(ex_cmd)
end

api.nvim_set_keymap(
	"n",
	"n",
	[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]],
	kopts
)
api.nvim_set_keymap(
	"n",
	"N",
	[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]],
	kopts
)
api.nvim_set_keymap("n", "*", [[*<Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]], kopts)
api.nvim_set_keymap("n", "#", [[#<Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]], kopts)
api.nvim_set_keymap("n", "g*", [[g*<Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]], kopts)
api.nvim_set_keymap("n", "g#", [[g#<Cmd>lua lazy_hlslens('lua require("hlslens").start()')<CR>]], kopts)

api.nvim_set_keymap("n", "<Leader>l", "<Cmd>noh<CR>", kopts)

api.nvim_create_autocmd({
	"CmdlineEnter",
}, {
	pattern = { "/", "?" },
	callback = function()
		if not package.loaded["hlslens"] then
			packadd("nvim-hlslens")
			require("hlslens").setup()
		end
	end,
	once = false,
	desc = "Lazy load hlslens on search events",
})

-- =====================================================================
-- Diffview
-- =====================================================================
local function load_diffview_and_execute(ex_cmd)
	if not package.loaded["diffview"] then
		packadd("diffview.nvim")
	end
	cmd(ex_cmd)
end

keymap("n", "<leader>do", function()
	load_diffview_and_execute("DiffviewOpen")
end, { noremap = true, silent = true, desc = "Lazy load Diffview and open" })

keymap("n", "<leader>dc", function()
	load_diffview_and_execute("DiffviewClose")
end, { noremap = true, silent = true, desc = "Close Diffview (lazy load compatible)" })
keymap("n", "<leader>df", function()
	load_diffview_and_execute("DiffviewFileHistory")
end, { noremap = true, silent = true, desc = "Lazy load Diffview and show file history" })

-- =====================================================================
-- Comment
-- =====================================================================
require("Comment").setup({
	toggler = {
		line = "<leader>c",
		block = "<leader>C",
	},
	opleader = {
		line = "<leader>c",
		block = "<leader>C",
	},
})

-- =====================================================================
-- Env
-- =====================================================================
vim.env.PATH = "/opt/homebrew/bin:" .. vim.env.HOME .. "/go/bin:/usr/local/go/bin:/usr/local/bin:" .. vim.env.PATH
