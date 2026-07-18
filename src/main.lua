local helper = require("src/helper")
local lexer = require("src/lexer")
local parser = require("src/parser")
local logger = require("src/logger")

local inspect = require("src/inspect")

local fname = arg[1]
local f = io.open(fname, "r")
if not f then
  logger.error("cannot open " .. fname)
end

local program = f:read("*all")
f:close()

logger.log("lexing %s fname", fname)
local toks = lexer.l(fname, program)
-- print("tokens: " .. inspect(toks))

logger.log("parsing %s fname", fname)
local ast = parser.p(toks)
print("ast: " .. inspect(ast))
