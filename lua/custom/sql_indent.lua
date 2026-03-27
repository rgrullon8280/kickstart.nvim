local M = {}

local CONTINUATION_WIDTH = 4

local function get_line(lnum)
  return vim.fn.getline(lnum)
end

local function normalize(text)
  return text:lower():gsub('%-%-.*$', ''):match('^%s*(.-)%s*$')
end

local function count_matches(text, pattern)
  local _, count = text:gsub(pattern, '')
  return count
end

local function prev_nonblank(lnum)
  return vim.fn.prevnonblank(lnum - 1)
end

local function sql_shiftwidth(bufnr)
  local sw = vim.bo[bufnr].shiftwidth
  if sw == 0 then
    sw = vim.bo[bufnr].tabstop
  end
  return sw > 0 and sw or 4
end

local function query_base_indent(bufnr, lnum)
  local depth = 0

  for i = lnum - 1, 1, -1 do
    local text = get_line(i)
    if text:match('%S') then
      local opens = count_matches(text, '%(')
      local closes = count_matches(text, '%)')

      if opens > closes then
        local unmatched = opens - closes
        if depth < unmatched then
          return vim.fn.indent(i) + sql_shiftwidth(bufnr)
        end
        depth = depth - unmatched
      elseif closes > opens then
        depth = depth + (closes - opens)
      end
    end
  end

  return 0
end

local function matching_open_indent(lnum)
  local depth = 1

  for i = lnum - 1, 1, -1 do
    local text = get_line(i)
    if text:match('%S') then
      depth = depth + count_matches(text, '%)')
      local opens = count_matches(text, '%(')
      if opens >= depth then
        return vim.fn.indent(i)
      end
      depth = depth - opens
    end
  end

  return 0
end

local function is_clause(text)
  return text:match('^with%f[%W]')
    or text:match('^select%f[%W]')
    or text:match('^from%f[%W]')
    or text:match('^where%f[%W]')
    or text:match('^group%f[%W]')
    or text:match('^order%f[%W]')
    or text:match('^having%f[%W]')
    or text:match('^qualify%f[%W]')
    or text:match('^limit%f[%W]')
    or text:match('^union%f[%W]')
    or text:match('^except%f[%W]')
    or text:match('^intersect%f[%W]')
    or text:match('^join%f[%W]')
    or text:match('^left%f[%W]')
    or text:match('^right%f[%W]')
    or text:match('^inner%f[%W]')
    or text:match('^full%f[%W]')
    or text:match('^cross%f[%W]')
end

local function is_continuation(text)
  return text:match('^and%f[%W]') or text:match('^or%f[%W]') or text:match('^on%f[%W]')
end

local function wants_continuation(text)
  return is_continuation(text)
    or text:match('^where%f[%W]')
    or text:match('^having%f[%W]')
    or text:match('^qualify%f[%W]')
    or text:match('^set%f[%W]')
    or text:match('^join%f[%W]')
    or text:match('^left%s+join%f[%W]')
    or text:match('^right%s+join%f[%W]')
    or text:match('^inner%s+join%f[%W]')
    or text:match('^full%s+join%f[%W]')
    or text:match('^cross%s+join%f[%W]')
end

function M.indent(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local base = query_base_indent(bufnr, lnum)
  local current = normalize(get_line(lnum))

  if current == '' then
    local prev = prev_nonblank(lnum)
    if prev == 0 then
      return 0
    end

    local previous = normalize(get_line(prev))
    if previous:sub(-1) == '(' then
      return base
    end

    if wants_continuation(previous) then
      return base + CONTINUATION_WIDTH
    end

    if previous:match('^%)') then
      return base
    end

    return vim.fn.indent(prev)
  end

  if current:match('^%)') then
    return matching_open_indent(lnum)
  end

  if current:match('^;') then
    return base
  end

  if current:match('^,') then
    return base == 0 and 0 or base - sql_shiftwidth(bufnr)
  end

  if is_continuation(current) then
    return base + CONTINUATION_WIDTH
  end

  if is_clause(current) then
    return base
  end

  local prev = prev_nonblank(lnum)
  if prev > 0 then
    return vim.fn.indent(prev)
  end

  return base
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  vim.bo[bufnr].expandtab = true
  vim.bo[bufnr].tabstop = 4
  vim.bo[bufnr].softtabstop = 4
  vim.bo[bufnr].shiftwidth = 4
  vim.bo[bufnr].autoindent = true
  vim.bo[bufnr].smartindent = false
  vim.bo[bufnr].cindent = false
  vim.bo[bufnr].indentexpr = "v:lua.require'custom.sql_indent'.indent(v:lnum)"
  vim.bo[bufnr].indentkeys = table.concat({
    '0)',
    '0]',
    '0,',
    '!^F',
    'o',
    'O',
    '0=~with',
    '0=~select',
    '0=~from',
    '0=~where',
    '0=~and',
    '0=~or',
    '0=~on',
    '0=~join',
    '0=~left',
    '0=~right',
    '0=~inner',
    '0=~full',
    '0=~cross',
    '0=~group',
    '0=~order',
    '0=~having',
    '0=~qualify',
    '0=~limit',
    '0=~union',
    '0=~except',
    '0=~intersect',
  }, ',')

  local undo = vim.b[bufnr].undo_ftplugin or ''
  local reset = 'setlocal expandtab< tabstop< softtabstop< shiftwidth< autoindent< smartindent< cindent< indentexpr< indentkeys<'
  if undo == '' then
    vim.b[bufnr].undo_ftplugin = reset
  else
    vim.b[bufnr].undo_ftplugin = undo .. ' | ' .. reset
  end
end

return M
