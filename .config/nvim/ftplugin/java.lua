--local config = {
    --cmd = {'/Users/princelo/.vim/pack/plugins/jdt-language-server-1.45.0-202502271238/bin/jdtls'},
    --root_dir = vim.fs.dirname(vim.fs.find({'gradlew', '.git', 'mvnw'}, { upward = true })[1]),
--}

-- If you started neovim within `~/dev/xy/project-1` this would resolve to `project-1`
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

local workspace_dir = vim.env.HOME .. '/javaWorkspaces/' .. project_name
--                                               ^^
--                                               string concattenation in Lua
-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local config = {
  -- The command that starts the language server
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  cmd = {

    -- 💀
    'java', -- or '/path/to/java21_or_newer/bin/java'
            -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx4g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. vim.env.HOME .. '/.vim/pack/plugins/lombok.jar',
    --'-Xbootclasspath/a:/Users/princelo/.vim/pack/plugins/lombok.jar',

    -- 💀
    '-jar', vim.env.HOME .. '/.vim/pack/plugins/jdt-language-server-1.56.0-202601291528/plugins/org.eclipse.equinox.launcher_1.7.100.v20251111-0406.jar',
         -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
         -- Must point to the                                                     Change this to
         -- eclipse.jdt.ls installation                                           the actual version


    -- 💀
    '-configuration', vim.env.HOME .. '/.vim/pack/plugins/jdt-language-server-1.56.0-202601291528/config_mac_arm',
                    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
                    -- Must point to the                      Change to one of `linux`, `win` or `mac`
                    -- eclipse.jdt.ls installation            Depending on your system.


    -- 💀
    -- See `data directory configuration` section in the README
    '-data', workspace_dir
  },

  -- 💀
  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  --
  -- vim.fs.root requires Neovim 0.10.
  -- If you're using an earlier version, use: require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
  root_dir = vim.fs.root(0, {".git", "mvnw", "gradlew"}),

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
    }
  },

  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = {
        vim.fn.glob(vim.env.HOME .. "/.local/share/nvim/site/pack/plugins/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.53.1.jar", 1)
    }
  },
}
-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.

local jdtls = function()
    if not package.loaded["jdtls"] then
        vim.cmd.packadd('nvim-jdtls')
    end
    require('jdtls').start_or_attach(config)
end

if vim.g.java == 1 then
    jdtls()
end

vim.api.nvim_create_user_command(
    "Jvm",
    function ()
        vim.g.java = 1
        jdtls()
    end,
    { bang = false }
)

vim.api.nvim_create_user_command(
    "JvmInstant",
    jdtls,
    { bang = false }
)
