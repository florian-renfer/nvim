-- Require jdtls
local status_ok, jdtls = pcall(require, 'jdtls')
if not status_ok then
  return
end

-- Home directory
local home = os.getenv 'HOME'

-- Convenience methods for setting up the jdtls language server
-- Requires mason-registry
local registry = require 'mason-registry'

-- Evaluates the required directories and paths for jdtls
local function get_jdtls_paths()
  local path = {}
  local jdtls_install = registry.get_package('jdtls'):get_install_path()

  path.data_dir = vim.fn.stdpath 'cache' .. '/nvim-jdtls'

  path.java_agent = jdtls_install .. '/lombok.jar'

  path.launcher_jar = vim.trim(vim.fn.glob(jdtls_install .. '/plugins/org.eclipse.equinox.launcher_*.jar'))

  if vim.fn.has 'mac' == 1 then
    path.platform_config = jdtls_install .. '/config_mac'
  elseif vim.fn.has 'unix' == 1 then
    path.platform_config = jdtls_install .. '/config_linux'
  elseif vim.fn.has 'win32' == 1 then
    path.platform_config = jdtls_install .. '/config_win'
  end

  return path
end

local path = get_jdtls_paths()

local cwd = vim.fn.getcwd()
local data_dir = path.data_dir .. '/' .. vim.fn.fnamemodify(cwd, ':p:h:t')

-- Create data_dir if it doesn't exist
if vim.fn.isdirectory(data_dir) == 0 then
  vim.fn.mkdir(data_dir, 'p')
end

-- Actual configuration for jdtls
local config = {
  cmd = {
    home .. '/.sdkman/candidates/java/17.0.10-amzn/bin/java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    -- '-javaagent:' .. path.java_agent,
    '-javaagent:/Users/florianrenfer/Downloads/lombok-edge.jar',
    '-Xmx4g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    '-jar',
    path.launcher_jar,
    '-configuration',
    path.platform_config,
    '-data',
    data_dir,
  },

  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  -- root_dir = { '.git', 'mvnw', 'gradlew' },

  -- Here you can configure eclipse.jdt.ls specific settings
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      configuration = {
        runtimes = {
          {
            name = 'JavaSE-11',
            path = home .. '/.sdkman/candidates/java/11.0.22-amzn',
          },
          {
            name = 'JavaSE-17',
            path = home .. '/.sdkman/candidates/java/17.0.10-amzn',
          },
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },

  -- Language server `initializationOptions`
  -- You need to extend the `bundles` with paths to jar files
  -- if you want to use additional eclipse.jdt.ls plugins.
  --
  -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  --
  -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
  init_options = {
    bundles = {},
  },
}

-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
jdtls.start_or_attach(config)
