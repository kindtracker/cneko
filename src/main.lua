local helper = require("src/helper")
local lexer = require("src/lexer")
local dump = helper.dump

local f = io.open(arg[1], "rb")
local program = f:read("*all")

local toks = lexer.l(program)
print(toks)
print(dump(toks))
