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

return M
