local script = debug.getinfo(1, "S").source:sub(2)
local dir = script:match("(.*/)")
package.path = dir .. "?.lua;" .. dir .. "?/init.lua;" .. package.path

local cneko = require("cneko")
local inspect = require("inspect")

local ast = cneko.compile(arg[1])
print(inspect(ast))
