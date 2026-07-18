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
  "fn", "void", "null",
  "float", "double",
  "if", "else",
  "switch", "case", "default",
  "for", "while", "break", "continue",
  "return", "const", "static", "const",
  "extern", "import", "struct", "union", 
  "enum", "typedef", "true", "false", "string"
}

M.ident = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
M.digits = "0123456789"
M.suffixes = "fFdDlLuUsS"
M.operators = "-+*/^><%="
M.delimiters = "(){}[]"
M.delimiter_tokens = {
  ["("] = {
    ["type"] = "lparen",
    ["value"] = "("
  },
  [")"] = {
    ["type"] = "rparen",
    ["value"] = ")"
  },
  ["{"] = {
    ["type"] = "lbrace",
    ["value"] = "{"
  },
  ["}"] = {
    ["type"] = "rbrace",
    ["value"] = "}"
  },
  ["["] = {
    ["type"] = "lbracket",
    ["value"] = "["
  },
  ["]"] = {
    ["type"] = "rbracket",
    ["value"] = "]"
  }
}
M.puncts = ",;:."
M.punct_tokens = {
  [","] = {
    ["type"] = "comma",
    ["value"] = ","
  },
  [";"] = {
    ["type"] = "semicolon",
    ["value"] = ";"
  },
  [":"] = {
    ["type"] = "colon",
    ["value"] = ":"
  },
  ["."] = {
    ["type"] = "dot",
    ["value"] = "."
  }
}
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
    row = row + 1
  end
  while idx <= #str do
    local char = str:sub(idx, idx)

    if char == "\n" then
      idx = idx + 1
      line = line + 1
      row = 1
    elseif contains(M.whitespace, char) then
      inc()
    elseif char == "/" and str:sub(idx+1, idx+1) == "/" then
      while idx <= #str and str:sub(idx, idx) ~= "\n" do
        idx = idx + 1
      end
    elseif char == "/" and str:sub(idx+1, idx+1) == "*" then
      idx = idx + 2
      while idx <= #str do
        if str:sub(idx, idx) == "*" and str:sub(idx+1, idx+1) == "/" then
          idx = idx + 2
          break
        end
        if str:sub(idx, idx) == "\n" then
          line = line + 1
          row = 0
        end
        idx = idx + 1
      end
    elseif contains(M.ident, char) then
      local start = idx
      while idx <= #str and (contains(M.ident, str:sub(idx, idx)) or contains(M.digits, str:sub(idx, idx))) do
        inc()
      end

      local val = str:sub(start, idx - 1)
      local type = (contains(M.keywords, val) and "keyword") or "ident"
      table.insert(toks, {["type"] = type, ["value"] = val, ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif contains(M.digits, char) then
      local start = idx
      while idx <= #str and contains(M.digits, str:sub(idx, idx)) do
        inc()
      end

      local val = str:sub(start, idx - 1)
      table.insert(toks, {["type"] = "number", ["value"] = val, ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif char == "-" and str:sub(idx+1,idx+1) == ">" then
      inc() inc()
      table.insert(toks, {["type"] = "rarrow", ["value"] = "->", ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif contains(M.delimiters, char) then
      inc() 
      local token = M.delimiter_tokens[char]
      table.insert(toks, {["type"] = token.type, ["value"] = token.value, ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif contains(M.puncts, char) then
      inc()
      local token = M.punct_tokens[char]
      table.insert(toks, {["type"] = token.type, ["value"] = token.value, ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif contains(M.operators, char) then
      inc()
      table.insert(toks, {["type"] = "operator", ["value"] = char, ["line"] = line, ["row"] = row, ["fname"] = fname})
    elseif char == '"' then
      local start = idx
      local val = ""
      inc()
      while idx <= #str and str:sub(idx, idx) ~= '"' do
        local chr = str:sub(idx, idx)
        if chr == "\\" and idx < #str then
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
      else 
        logger.error("%s:%d:%d expected: \"", file, line, row)
      end
      table.insert(toks, {["type"] = "string", ["value"] = val, ["line"] = line, ["row"] = row, ["fname"] = fname})
    else
      logger.error("%s:%d:%d: invalid token: '%s'", file, line, row, char)
      inc()
    end
  end
  return toks
end

return M
