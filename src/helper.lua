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

function M.dump(o)
 if type(o) == 'table' then
   local s = '{ '
   for k,v in pairs(o) do
     local key = k
     if type(k) ~= 'number' then key = '"'..k..'"' end
       s = s .. '['..key..'] = ' .. M.dump(v) .. ','
     end
     return s .. '} '
  else
    return tostring(o)
  end
end

return M
