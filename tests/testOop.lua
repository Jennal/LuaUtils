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

        p = Point:new(10, 20)
        assertEquals(p.x, 10)
        assertEquals(p.y, 20)
    end

    function TestOop:testFinalInherit()
        local Point = Oop.class("Point", function()
            return {x = 1, y = 2}
        end)

        -- inheirt from function can do depth single inherit
        local P1 = Oop.class("P1", Point)
        local P2 = Oop.class("P2", P1)
        local P3 = Oop.class("P3", P2)

        local p = P1:new()
        assertEquals(1, p.x)
        assertEquals(2, p.y)

        p = P2:new()
        assertEquals(1, p.x)
        assertEquals(2, p.y)

        p = P3:new()
        assertEquals(1, p.x)
        assertEquals(2, p.y)

        -- multi inheirt from function only support with one
        assertErrorMsgContains('can\'t mutiple inherit from cpp obeject', function()
            local MP1 = Oop.class("MP1", P2, P1)
        end)

        -- inheirt from function can only be multi inherit once
        local MP2 = Oop.class("MP2", P2, Oop.Obj) -- become final class
        p = MP2:new()
        assertEquals(1, p.x)
        assertEquals(2, p.y)

        assertErrorMsgContains("can't inherit from final obeject", function()
            local MP3 = Oop.class("MP3", MP2)
        end)

        assertErrorMsgContains("can't inherit from final obeject", function()
            local MP4 = Oop.class("MP4", MP2, Oop.Obj)
        end)
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

    function TestOop:testInheritSingleWithOutCtor()
        local Base = Oop.class("Base", Oop.Obj)

        local o = Base:new()
        assertTrue(o)
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

        local o = D:new() -- automatic super ctor call
        assertTrue(o:bool())
        assertEquals("bool", o.bb) -- trick D inheirt ctor from B
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
            E.super.D.ctor(self)
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

    function TestOop:testMultiInheiritSuperCtor()
        local IAttackive = Oop.interface("IAttackive", {
            {"attack", "(monster)", "attack monster"},
        },{
        })
        local Attack = Oop.class("Attack", IAttackive, Oop.Obj)
        local Sprite = Oop.class("Sprite", function() return {x=1, y=2} end)
        local Base1 = Oop.class("Base1", Oop.Obj)
        local Test = Oop.class("Test", Sprite, Base1, Attack.Attackive)

        local o = Test:new()
        -- print("o.x, o.y", o, o.x, o.y)
        assertEquals(1, o.x)
        assertEquals(2, o.y)

        function Base1:ctor()
            -- print("Base1:ctor", self, self.class.__cname)
            self.d = "d"
        end

        function Sprite:ctor()
            -- print("Sprite:ctor", self, self.class.__cname)
            self.x = 10
            self.y = 20
        end

        function Test:ctor()
            Test.super.Sprite.ctor(self)
            Test.super.Base1.ctor(self)
        end

        o = Test:new()
        -- print("o.x, o.y, o.d", o, o.x, o.y, o.d)
        assertEquals(10, o.x)
        assertEquals(20, o.y)
        assertEquals("d", o.d)

        function Test:ctor(...)
            Test.super.Sprite.ctor(self)
            Test.super.Base1.ctor(self)

            -- print("Test:ctor", self, self.class.__cname)
            self.z = 30
        end

        o = Test:new()
        -- print("o.x, o.y, o.z, o.d", o, o.x, o.y, o.z, o.d)
        assertEquals(10, o.x)
        assertEquals(20, o.y)
        assertEquals(30, o.z)
        assertEquals("d", o.d)
    end
-- end of table TestOop
