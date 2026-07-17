local M = {}

function M.contains(tbl, value)
  if type(tbl) == "string" then
    return string.find(tbl, value, 1, true) ~= nil
  else
    for i, v in ipairs(tbl) do
      if v == value then
        return true
      end
    end
  end
  return false
end

function M.tslice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

return M
