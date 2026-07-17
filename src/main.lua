local helper = require("src/helper")
local lexer = require("src/lexer")
local parser = require("src/parser")
local logger = require("src/logger")

local inspect = require("src/inspect")

local fname = arg[1]
local f = io.open(fname, "rb")
local program = f:read("*all")

logger.log("lexing %s file", fname)
local toks = lexer.l(fname, program)
logger.log("parsing %s file", fname)
local ast = parser.p(toks)

print("ast: " .. inspect(ast))
