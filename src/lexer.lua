local helper = require("src/helper")
local contains = helper.contains
local M = {}

M.keywords = {
  "bool", "ichar", "char",
  "short", "ushort",
  "int", "uint",
  "long", "ulong",
  "iptr", "uptr", 
  "sz", "usz",
  "fn", "void", "null"
}

M.ident = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
M.digits = "0123456789"
M.operators = "-+*/^><%"
M.whitespace = " \t\n\r"

function M.l(str)
  local idx = 1
  local toks = {}

  local function inc()
    idx = idx + 1
  end
  while idx <= #str do
    local char = str:sub(idx, idx)
    if contains(M.ident, char) then
      local start = idx
      while idx <= #str and contains(M.ident, str:sub(idx, idx)) do
        inc()
      end
      table.insert(toks, str:sub(start, idx - 1))
    elseif contains(M.digits, char) then
      table.insert(toks, char)
      inc()
    else
      inc()
    end
  end
  return toks
end

return M
