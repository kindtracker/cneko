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

function M.pparm_list(toks, idx)
  local parm_list = {}

  M.expect(toks, idx, "lparen");
  idx = idx + 1
  while idx <= #toks do 
    local name = toks[idx].value
    if name == ")" then
      break
    end

    idx = idx + 1
    M.expect(toks, idx, "colon")
    idx = idx + 1
    local type = M.expect(toks, idx, "keyword").value
    table.insert(parm_list, {["name"] = name, ["type"] = type})
  end
  M.expect(toks, idx, "rparen");
  idx = idx + 1

  return parm_list, idx
end

function M.pfunc(toks, idx)
  local func = {}
  func.type = "fn_decl"
  func.name = M.expect(toks, idx, "ident").value
  idx = idx + 1
  func.parm_list, idx = M.pparm_list(toks, idx)
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
