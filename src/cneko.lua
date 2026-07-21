local helper = require("helper")
local lexer = require("compiler/lexer")
local parser = require("compiler/parser")
local logger = require("logger")

local M = {}

function M.compile(fname)
  print(fname)
  local f = io.open(fname, "r")
  if not f then
    logger.error("cannot open " .. fname)
  end
  local program = f:read("*all")
  f:close()

  logger.log("lexing %s file", fname)
  local toks = lexer.l(fname, program)
  logger.log("parsing %s file", fname)
  local ast = parser.p(toks)
  return ast
end

return M
