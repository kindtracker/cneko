local logger = require("src/logger")

local inspect = require("src/inspect")

local M = {}

function M.expect(toks, idx, type)
  local tok = toks[idx]
  if toks[idx].type == type then
    return tok
  else
    logger.error("%s:%d:%d: expected token: '%s' but got %s (%s)", tok.fname, tok.line, tok.row, type, tok.type, tok.value)
  end
end

function M.pstat(toks, idx)
end

function M.pblock(toks, idx)
  local block = {}
  
  M.expect(toks, idx, "lbrace");
  idx = idx + 1
  while idx <= #toks do 
    local tok = toks[idx]
    if tok.type == "rbrace" then
      break
    end 
    local stat;
    stat, idx = M.pstat(toks, idx)
    table.insert(block, stat)
    idx = idx + 1
  end
  M.expect(toks, idx, "rbrace")
  idx = idx + 1
  return block, idx
end

function M.pnumber(toks, idx)
  local n = 0
  n = M.expect(toks, idx, "number")
  return n, idx
end

-- const int[1+1]
function M.ptype(toks, idx)
  local t = {
    ["const"] = false,
    ["is_array"] = false,
    ["auto_array"] = false,
    ["array_size"] = 0,
    ["type"] = "int"
  }
  local tok = toks[idx]
  if tok.type == "keyword" then
    if tok.value == "const" then
      t.const = true
      idx = idx + 1
    end
  end
  t.type = toks[idx].value
  idx = idx + 1
  tok = toks[idx]
  if tok.type == "lbracket" then
    idx = idx + 1
    tok = toks[idx]
    t.is_array = true
    if tok.type == "rbracket" then
      t.auto_array = true
      idx = idx + 1
      return t, idx
    end
    t.array_size, idx = M.pnumber(toks, idx)
  end

  return t, idx
end

function M.pparm_list(toks, idx)
  local parm_list = {}

  M.expect(toks, idx, "lparen");
  idx = idx + 1
  while idx <= #toks do 
    local name = toks[idx].value
    if name == ")" then
      break
    elseif name == "," then
      idx = idx + 1
      name = toks[idx].value
    end
    idx = idx + 1
    M.expect(toks, idx, "colon")
    idx = idx + 1

    local type 
    type, idx = M.ptype(toks, idx)
    table.insert(parm_list, {["name"] = name, ["type"] = type})
  end
  M.expect(toks, idx, "rparen");
  idx = idx + 1

  return parm_list, idx
end

function M.pfunc(toks, idx)
  local func = {}
  local tok;
  func.type = "fn_decl"
  func.name = M.expect(toks, idx, "ident").value
  idx = idx + 1
  func.parm_list, idx = M.pparm_list(toks, idx)
  func.return_type = "void"
  tok = toks[idx]
  if tok.type == "rarrow" then
    idx = idx + 1
    tok = toks[idx]
    func.return_type = M.expect(toks, idx, "keyword").value
    idx = idx + 1
  end
  func.body, idx = M.pblock(toks, idx)
  return func, idx
end

function M.pstat(toks, idx)
  local stat = {}
  local ftok = toks[idx]
  idx = idx + 1
  if ftok.type == "keyword" then
    if ftok.value == "fn" then
      stat, idx = M.pfunc(toks, idx)
    end
  end
  return stat, idx
end

function M.p(toks)
  local ast = {}
  local idx = 1

  while idx <= #toks do
    local stat
    stat, idx = M.pstat(toks, idx)
    table.insert(ast, stat)
  end

  return ast
end

return M
