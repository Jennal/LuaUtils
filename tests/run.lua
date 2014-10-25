
package.path = package.path .. ";../src/?.lua"

require("luaunit")
require("testOop")

local lu = LuaUnit.new()
os.exit(lu:runSuite())
