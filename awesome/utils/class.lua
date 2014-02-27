return function (base, init)
   local cls = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class
      for k,v in pairs(base) do
         cls[k] = v
      end
      cls._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   cls.__index = cls

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
      local obj = {}
      setmetatable(obj,cls)
      if class_tbl.init then
         class_tbl.init(obj, ...)
      else 
         -- make sure that any stuff from the base class is initialized!
         if base and base.init then
            base.init(obj, ...)
         end
      end
      return obj
   end
   cls.init = init
   cls.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do 
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(cls, mt)
   return cls
end