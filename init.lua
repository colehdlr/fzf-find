local M = {}

local defaults = {
  fd_cmd = { 'fd', '--type', 'f', '--hidden', '--exclude', '.git' },
}

local config = vim.deepcopy(defaults)
local cached_files = nil

local function list_files()
  local files = vim.fn.systemlist(config.fd_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('fd failed: ' .. table.concat(files, '\n'), vim.log.levels.ERROR)
    return {}
  end
  return files
end

local function fuzzy_filter(files, query)
  return vim.fn.systemlist({ 'fzf', '--scheme=path', '--filter=' .. query }, files)
end

local function missing_executable()
  for _, bin in ipairs({ config.fd_cmd[1], 'fzf' }) do
    if vim.fn.executable(bin) == 0 then
      return bin
    end
  end
end

function M.find(query)
  if cached_files == nil then
    cached_files = list_files()
  end
  if query == '' then
    return cached_files
  end
  return fuzzy_filter(cached_files, query)
end

function M.refresh()
  cached_files = nil
end

function M.setup(opts)
  if vim.fn.has('nvim-0.11') == 0 then
    vim.notify('fzf-find.nvim requires Neovim 0.11+', vim.log.levels.ERROR)
    return
  end

  config = vim.tbl_extend('force', defaults, opts or {})

  local missing = missing_executable()
  if missing then
    vim.notify(('fzf-find.nvim: `%s` not found in PATH'):format(missing), vim.log.levels.ERROR)
    return
  end

  vim.o.findfunc = "v:lua.require'fzf-find'.find"

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    group = vim.api.nvim_create_augroup('FzfFindCache', { clear = true }),
    pattern = ':',
    callback = M.refresh,
  })
end

return M
