-- Format only changed lines on save using gitsigns hunks
-- This configuration uses gitsigns.nvim to detect changed lines and formats only those ranges

-- Filetypes to disable formatting for
local disable_filetypes = { c = true, cpp = true }

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('FormatChangedLines', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local filetype = vim.bo[bufnr].filetype

    -- Skip disabled filetypes
    if disable_filetypes[filetype] then
      return
    end

    -- Check if conform is available
    local conform_ok, conform = pcall(require, 'conform')
    if not conform_ok then
      return
    end

    -- Try to get hunks from gitsigns buffer cache
    local hunks = {}
    local gitsigns_ok, gitsigns_cache = pcall(function()
      return require('gitsigns.cache').cache[bufnr]
    end)

    if gitsigns_ok and gitsigns_cache and gitsigns_cache.hunks then
      hunks = gitsigns_cache.hunks
    end

    -- If we have hunks, format only changed ranges
    if #hunks > 0 then
      for _, hunk in ipairs(hunks) do
        -- hunk.added contains {start, count} for added/modified lines
        if hunk.added and hunk.added.count > 0 then
          local start_line = hunk.added.start
          local end_line = hunk.added.start + hunk.added.count - 1

          conform.format {
            bufnr = bufnr,
            lsp_format = 'fallback',
            timeout_ms = 500,
            range = {
              start = { start_line, 0 },
              ['end'] = { end_line, 0 },
            },
          }
        end
      end
    else
      -- No hunks found - file might be untracked, new, or no changes
      -- Format entire buffer as fallback
      conform.format {
        bufnr = bufnr,
        lsp_format = 'fallback',
        timeout_ms = 500,
      }
    end
  end,
})

-- Return empty table to satisfy lazy.nvim's expectation for plugin files
return {}
