local M = {}

local reset = "\27[0m"
local black = "\27[30m"
local red = "\27[31m"
local green = "\27[32m"
local yellow = "\27[33m"
local blue = "\27[34m"
local magenta = "\27[35m"
local cyan = "\27[36m"
local white = "\27[37m"

function M.log(text, ...)
  local source = debug.getinfo(2).source
  print(string.format("[" .. green .. "log" .. reset .. "] %s: " .. text, source, ...))
end

function M.warning(text, ...)
  local source = debug.getinfo(2).source
  print(string.format("[" .. yellow .. "warning" .. reset .. "] %s: " .. text, source, ...))
end

function M.error(text, ...)
  local source = debug.getinfo(2).source
  print(string.format("[" .. red .. "error" .. reset .. "] %s: " .. text, source, ...))
  os.exit(1)
end


return M
