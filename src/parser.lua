local helper = require("src/helper")
local logger = require("src/logger")
local contains = helper.contains

local inspect = require("src/inspect")

local M = {}

M.types = {
  "int", "string", "bool", "char", "float", "double", "void",
  "ichar", "short", "ushort", "uint", "long", "ulong", "iptr", "uptr", "sz", "usz"
}

function M.expect(toks, idx, type)
  local tok = toks[idx]
  
  if tok == nil then
    logger.error("invalid token")
  end
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

function M.pexpr(toks, idx)
  local expr = {}
  local tok = toks[idx]
  
  if tok.type == "lparen" then
    idx = idx + 1
    expr, idx = M.pexpr(toks, idx)
    M.expect(toks, idx, "rparen")
    idx = idx + 1
  elseif tok.type == "number" then
    expr = {type = "number", value = tok.value}
    idx = idx + 1
  elseif tok.type == "ident" then
    local next_tok = toks[idx + 1]
    if next_tok and next_tok.type == "lparen" then
      expr, idx = M.pcall_expr(toks, idx)
    else
      expr = {type = "ident", value = tok.value}
      idx = idx + 1
    end
  end
  
  while idx <= #toks and toks[idx].type == "operator" do
    local op = toks[idx].value
    idx = idx + 1
    local right_tok = toks[idx]
    local right
    if right_tok.type == "lparen" then
      idx = idx + 1
      right, idx = M.pexpr(toks, idx)
      M.expect(toks, idx, "rparen")
      idx = idx + 1
    elseif right_tok.type == "number" then
      right = {type = "number", value = right_tok.value}
      idx = idx + 1
    elseif right_tok.type == "ident" then
      right = {type = "ident", value = right_tok.value}
      idx = idx + 1
    end
    expr = {type = "binop", op = op, left = expr, right = right}
  end
  
  return expr, idx
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

function M.parg_list(toks, idx)
  local arg_list = {}

  M.expect(toks, idx, "lparen");
  idx = idx + 1
  while idx <= #toks do 
    local tok = toks[idx]
    if tok.type == "rparen" then
      break
    elseif tok.type == "comma" then
      idx = idx + 1
      tok = toks[idx]
    end
    idx = idx + 1

    table.insert(arg_list, tok)
  end
  M.expect(toks, idx, "rparen");
  idx = idx + 1

  return arg_list, idx
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

function M.preturn(toks, idx)
  local ret = {}
  local tok
  ret.type = "return"
  ret.value = 0
  idx = idx + 1
  ret.value, idx = M.pexpr(toks, idx)
  M.expect(toks, idx, "semicolon")
  idx = idx + 1
  return ret, idx
end

function M.pcall_expr(toks, idx)
  local call_expr = {}
  call_expr.type = "call"
  local namespace = {}
  
  local tok = M.expect(toks, idx, "ident")
  table.insert(namespace, tok.value)
  idx = idx + 1
    
  while idx <= #toks and toks[idx].type == "colon" do
    idx = idx + 1
    if toks[idx].type == "ident" then
      table.insert(namespace, toks[idx].value)
      idx = idx + 1
    end
  end
  call_expr.namespace = namespace 
  call_expr.arg_list, idx = M.parg_list(toks, idx)
  return call_expr, idx
end

function M.pvar_decl(toks, idx)
  local var = {}
  var.type = "var_decl"
  var.var_type, idx = M.ptype(toks, idx)
  var.name = M.expect(toks, idx, "ident").value
  idx = idx + 1
  local tok = toks[idx]
  if tok.type == "operator" and tok.value == "=" then
    idx = idx + 1
    var.value, idx = M.pexpr(toks, idx)
  end

  M.expect(toks, idx, "semicolon")
  idx = idx + 1
  return var, idx
end

function M.passign(toks, idx)
  local assign = {}
  assign.type = "assign"  
  assign.name = M.expect(toks, idx, "ident").value
  idx = idx + 1
  M.expect(toks, idx, "operator")
  idx = idx + 1
  assign.value = M.pexpr(toks, idx)
  M.expect(toks, idx, "semicolon")
  idx = idx + 1
  return assign, idx
end

function M.pif(toks, idx)
  local ifs = {}
  ifs.type = "if"
  M.expect(toks, idx, "lparen")
  idx = idx + 1
  ifs.cond, idx = M.pexpr(toks, idx)
  M.expect(toks, idx, "rparen")
  idx = idx + 1
  
  if toks[idx].type == "lbrace" then
    ifs.body, idx = M.pblock(toks, idx)
  else
    ifs.body, idx = {M.pstat(toks, idx)}
  end
  return ifs, idx
end

function M.pstat(toks, idx)
  local stat = {}
  local tok = toks[idx]

  if tok.type == "keyword" and not contains(M.types, tok.value) then
    if tok.value == "fn" then
      idx = idx + 1
      stat, idx = M.pfunc(toks, idx)
    elseif tok.value == "if" then
      idx = idx + 1
      stat, idx = M.pif(toks, idx)
    elseif tok.value == "return" then
      stat, idx = M.preturn(toks, idx)
    else
      logger.error("%s:%d:%d: no match for token: %s (%s)", tok.fname, tok.line, tok.row, tok.value, tok.type)
    end
  elseif tok.type == "ident" then
    tok = toks[idx+1]
    if tok and tok.type == "operator" then
      stat, idx = M.passign(toks, idx)
    else
      stat, idx = M.pcall_expr(toks, idx)
      M.expect(toks, idx, "semicolon")
      idx = idx + 1
    end
  elseif contains(M.types, tok.value) then
    stat, idx = M.pvar_decl(toks, idx)
  else
    logger.error("%s:%d:%d: no match for token: %s (%s)", tok.fname, tok.line, tok.row, tok.value, tok.type)
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
