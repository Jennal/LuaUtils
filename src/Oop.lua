local InheritType = {
    FINAL     = 0,
    CPP       = 1,
    LUA       = 2,
    INTERFACE = 3,
}

local Oop = {}

Oop.Obj = {
    __cname = "Obj",
    __ctype = InheritType.LUA,
    ctor = function(self, ...) end,
}

function Oop.Obj.__create(self, ...)
    local instance = {}

    self.__index = self
    setmetatable(instance, self)
    instance.class = self
    
    return instance
end

function Oop.Obj.new(self, ...)
    local instance = self:__create(...)
    instance:ctor(...)
    
    return instance
end

local function copy_from_super(instance, super)
    local s = super
    while s do
        for k, v in pairs(s) do
            if not instance[k] then
                instance[k] = v
            end
        end

        if s.__multi_inheirt then
            for k, v in pairs(s.super) do
                copy_from_super(instance, v)
            end
            break
        end

        s = s.super
    end 
end

local function create_class_from_func(classname, super)
    local superType = type(super)
    local cls

    -- inherited from native C++ Object
    cls = {}

    if superType == "table" then
        -- copy fields from super
        -- for k,v in pairs(super) do cls[k] = v end
        cls = Oop.Obj.__create(super)
        cls.__create = super.__create
        cls.super    = super
        cls.new      = super.new
    else
        cls.__create = function(self, ...) return super(...) end
        cls.ctor = Oop.Obj.ctor
        function cls:new(...)
            local instance = self:__create(...)

            -- copy fields from class to native object
            for k,v in pairs(self) do instance[k] = v end -- TODO: why this make it work?
            copy_from_super(instance, self)

            instance.class = self
            instance:ctor(...)

            return instance
        end
    end
    
    cls.__cname = classname
    cls.__ctype = InheritType.CPP
    cls.__multi_inheirt = false

    return cls
end

local function create_class(name, super)
    if type(super) ~= "function" and type(super) ~= "table" then
        super = Oop.Obj
    end

    if type(super) == "function" or (super and super.__ctype == InheritType.CPP) then
        return create_class_from_func(name, super)
    end
    
    -- create from lua
    local o = super:__create()
    o.__cname = name
    o.__multi_inheirt = false
    o.class   = false -- means this is not instance
    o.super   = super
    
    return o
end

--- to define interface
-- @usage Test = Oop.interface({
--  {"func1", "(param1, param2) void", "description"},
--  {"func2", "(void) void", "desc"},
--  {"member", "desc"}
-- })
function Oop.interface(name, funcs, members)
    local infc  = {}
    local _funcs = {}
    local _members = {}
    
    if funcs then
        for _, val in ipairs(funcs) do
            _funcs[val[1]] = val
        end
    end
    
    if members then
        for _, val in ipairs(members) do
        	_members[val[1]] = val
        end
    end
    
    infc.__cname = name
    infc.__ctype = InheritType.INTERFACE -- interface
    infc.interfaces = _funcs
    infc.members    = _members
    
    infc.__index = function(t, key)
        local unpack = unpack or table.unpack
        
        if t.interfaces[key] then
            local name, params, desc = unpack(t.interfaces[key])
            local msg = string.format("%s.%s%s is not implemented: %s", infc.__cname, name, params, desc)
            error(msg, 2)
        end
        
        if t.members[key] then
            local name, desc = unpack(t.members[key])
            local msg = string.format("%s.%s is not defined: %s", infc.__cname, name, desc)
            error(msg, 2)
        end
    end
    
    setmetatable(infc, infc)
    
    return infc
end

function Oop.class(name, ...)
    local supers = {...}
    local cls
    if #supers > 1 then
        cls = Oop.inheritMulti(name, supers)
    else
        cls = Oop.inheritSingle(name, supers[1])
    end
    
    cls[name] = cls -- make A.super.B possible
    
    return cls
end

function Oop.inheritSingle(name, super)
    if super and type(super) ~= "function" and super.__ctype == InheritType.FINAL then
        error("can't inherit from final obeject", 2)
    end
    
    return create_class(name, super)
end

local function search(list, key)
    local super
    for i = 1, #list do
        super = list[i]
        if super[key] then
            return super[key]
        end
    end
end

function Oop.inheritMulti(name, supers)
    local cls = {}
    
    cls.__cname = name
    cls.class   = false -- means this is not instance
    cls.__multi_inheirt = true
    cls.super = {}
    
    for _, super in ipairs(supers) do
        if super.__ctype == InheritType.FINAL then
            error("can't inherit from final obeject", 2)
        end
    
    	cls.super[super.__cname] = super
        if super.__ctype == InheritType.CPP then
            if cls.__ctype == InheritType.CPP then error("can't mutiple inherit from cpp obeject", 2) end
            
            cls.__create = super.__create
            cls.new      = super.new
            cls.__ctype  = InheritType.CPP
            -- cls.__ctype  = InheritType.FINAL -- inherit from cpp obj, final inherit
        end
    end

    setmetatable(cls, {
        __index = function(t, k)
            return search(supers, k)
        end
    })

    return cls
end

function Oop.isClass(obj, name)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then
        return false
    end

    local cls = obj.class or obj

    if not cls then
        return false
    end

    if cls.__cname == name then
        return true
    end
    
    if not cls.super then
        return false
    end
    
    if not cls.__multi_inheirt then
        return Oop.isClass(cls.super, name)
    end
    
    for _, super in pairs(cls.super) do
        if Oop.isClass(super, name) then
            return true
        end
    end

    return false
end

function Oop.checkClass(obj, name, i)
    if not Oop.isClass(obj, name) then
        i = i or ""
        error("param"..i.." should be "..name.." type", 3)
    end
end

return Oop