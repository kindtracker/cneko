local helper = require("src/helper")
local logger = require("src/logger")
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
M.suffixes = "fFdDlLuUsS"
M.operators = "-+*/^><%"
M.whitespace = " \t\n\r"
M.escapes = {
  ["n"] = "\n",
  ["t"] = "\t",
  ["r"] = "\r",
  ["\\"] = "\\",
  ["b"] = "\b",
  ["f"] = "\f",
  ["v"] = "\v",
  ["\""] = "\"",
  ["'"] = "'",
  ["0"] = "\0"
}

function M.l(file, str)
  local idx = 1
  local line = 1
  local row = 0
  local toks = {}

  local function inc()
    idx = idx + 1
  end
  while idx <= #str do
    local char = str:sub(idx, idx)
    if char == "\n" then
      line = line + 1
      row = 1
      goto continue
    end
    row = row + 1
    if contains(M.whitespace, char) then
      inc()
      goto continue
    end

    if contains(M.ident, char) then
      local start = idx
      while idx <= #str and contains(M.ident, str:sub(idx, idx)) do
        inc()
      end

      local val = str:sub(start, idx - 1)
      local type = (contains(M.keywords, val) and "keyword") or "ident"
      table.insert(toks, {["type"] = type, ["value"] = val})
    elseif contains(M.digits, char) then
      local start = idx
      while idx <= #str and contains(M.digits, str:sub(idx, idx)) do
        inc()
      end

      local val = str:sub(start, idx - 1)
      table.insert(toks, {["type"] = "number", ["value"] = val})
    elseif char == '"' then
      local start = idx
      local val = ""
      inc()
      while idx <= #str and str:sub(idx, idx) ~= '"' do
        local chr = str:sub(idx, idx)
        if chr == "\\" then
          inc()
          local esc_chr = str:sub(idx, idx)
          if M.escapes[esc_chr] then
            val = val .. M.escapes[esc_chr]
          else
            val = val .. esc_chr
          end
        else
          val = val .. chr
        end
        inc()
      end
      if str:sub(idx, idx) == '"' then
        inc()
      end
      table.insert(toks, {["type"] = "string", ["value"] = val})
    else
      logger.error("%s:%d:%d: invalid token: %s", file, line, row, char)
      inc()
    end

    ::continue::
  end
  return toks
end

return M
