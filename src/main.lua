local helper = require("src/helper")
local lexer = require("src/lexer")
local logger = require("src/logger")

local inspect = require("src/inspect")

local fname = arg[1]
local f = io.open(fname, "rb")
local program = f:read("*all")

logger.log("lexing %s file", fname)
local toks = lexer.l(fname, program)

print(inspect(toks))
