require("luaunit")

package.path = package.path .. ";../src/?.lua;../src/?/init.lua"
Oop = require("Oop")

TestOop = {}
    function TestOop:testInterface()
        local IA = Oop.interface("IA", {
            {"func1", "(param1, param2)", "description"},
            {"func2", ""},
        },{
            {"member", ""}
        })

        assertEquals(IA.__cname, "IA")
        assertErrorMsgContains('func1(param1, param2) is not implemented', function() IA.func1() end)
        assertErrorMsgContains('member is not defined', function() local test = IA.member end)

        local IAImpl = Oop.class("IAImpl", Oop.Obj, IA)

        function IAImpl:func2()
            return true
        end
        IAImpl.member = 1

        local o = IAImpl:new()
        assertErrorMsgContains('func1(param1, param2) is not implemented', function() o:func1() end)
        assertTrue(o:func2())
        assertEquals(o.member, 1)
    end

    function TestOop:testCreateClassFromFunction()
        local Point = Oop.class("Point", function()
            return {x = 1, y = 2}
        end)

        local p = Point.new()
        assertEquals(p.x, 1)
        assertEquals(p.y, 2)

        function Point:ctor(x, y)
            self.x = x
            self.y = y
        end

        p = Point.new(10, 20)
        assertEquals(p.x, 10)
        assertEquals(p.y, 20)
    end

    function TestOop:testInheritSingle()
        local Base = Oop.class("Base", Oop.Obj)

        function Base:ctor()
            self.x = 1
            self.y = 2
        end

        local o = Base:new()
        assertEquals(o.x, 1)
        assertEquals(o.y, 2)

        local Delivery = Oop.inheritSingle("Delivery", Base)
        assertEquals(Delivery.x, 1)
        assertEquals(Delivery.y, 2)

        function Delivery:ctor()
            self.x = 10
        end

        local obj = Delivery:new()
        assertEquals(obj.x, 10)
        assertEquals(obj.y, 2)
    end

    function TestOop:testInheritMulti()
        local IA = Oop.interface("IA", {
            {"func1", "(p1, p2)", "IA.func1 desc"},
        },{
            {"member", "IA.member desc"}
        })

        local B = Oop.class("B", Oop.Obj)

        function B:ctor()
            self.bb = "bool"
        end

        function B:bool()
            return true
        end

        local C = Oop.class("C", Oop.Obj)
        function C:ctor()
            self.cc = "cool"
        end

        local D = Oop.class("D", IA, B, C)

        local o = D:new()
        assertTrue(o:bool())
        assertEquals("bool", o.bb) -- trick, because the first equal key in __index
        assertNotEquals("cool", o.cc)
        assertErrorMsgContains("IA.member is not defined", function() local a = o.member end)
        assertErrorMsgContains("IA.func1(p1, p2) is not implemented", function() o:func1() end)

        function D:ctor()
            D.super.B.ctor(self)
            D.super.C.ctor(self)
            self.member = 10
        end

        function D:func1()
            return true
        end

        o = D:new()

        assertTrue(o:bool())
        assertEquals("bool", o.bb)
        assertEquals("cool", o.cc)
        assertEquals(10, o.member)
        assertTrue(o:func1())

        local E = Oop.class("E", D)
        
        function E:ctor()
            self:superCtor()
            self.ee = 11
        end

        o = E:new()

        assertTrue(o:bool())
        assertEquals("cool", o.cc)
        assertEquals(10, o.member)
        assertEquals(11, o.ee)
        assertTrue(o:func1())
    end

    function TestOop:testConflictFunction()
        local A = Oop.class("A", Oop.Obj)
        local B = Oop.class("B", Oop.Obj)

        function A:name()
            return "a"
        end

        function B:name()
            return "b"
        end

        local C = Oop.class("C", A, B)

        assertEquals("a", C:name())
        assertEquals("b", C.super.B.name(C))

        local oc = C:new()

        assertEquals("a", oc:name())
        assertEquals("b", oc.class.super.B.name(oc))
    end

    function TestOop:testIsClassSingle()
        local Base = Oop.class("Base", Oop.Obj)

        function Base:ctor()
            self.x = 1
            self.y = 2
        end

        assertTrue(Oop.isClass(Base, "Base"))

        local obj = Base:new()
        assertTrue(Oop.isClass(obj, "Base"))
        assertFalse(Oop.isClass(obj, "Delivery"))

        local Delivery = Oop.inheritSingle("Delivery", Base)
        assertTrue(Oop.isClass(Delivery, "Base"))
        assertTrue(Oop.isClass(Delivery, "Delivery"))

        function Delivery:ctor()
            self.x = 10
        end

        obj = Delivery:new()
        assertTrue(Oop.isClass(obj, "Base"))
        assertTrue(Oop.isClass(obj, "Delivery"))
        assertFalse(Oop.isClass(obj, "Delivery2"))
    end

    function TestOop:testIsClassMulti()
        local IA = Oop.interface("IA", {
            {"func1", "p1, p2", "IA.func1 desc"},
        },{
            {"member", "IA.member desc"}
        })

        local C = Oop.class("C", Oop.Obj)
        local D = Oop.class("D", IA, C)

        local o = D:new()

        assertTrue(Oop.isClass(o, "Obj"))
        assertTrue(Oop.isClass(o, "IA"))
        assertTrue(Oop.isClass(o, "C"))
        assertTrue(Oop.isClass(o, "D"))
    end
-- end of table TestOop

local lu = LuaUnit.new()
os.exit(lu:runSuite())