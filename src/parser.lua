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

function M.p(toks)
  local ast = {}
  local idx = 1

  local function inc()
    idx = idx + 1
  end

  while idx <= #toks do
    local tok = toks[idx]

    if tok.type == "keyword" then
      if tok.value == "fn" then
        inc()
        local name = M.expect(toks, idx, "ident")
        table.insert(ast, {["type"] = "func_decl", ["name"] = name.value})
      else 
        inc()
      end
    else 
      inc()
    end
  end

  return ast
end

return M
