function table.find(tab, val)
    for k, v in pairs(tab) do
        if v == val then
            return k
        end
    end
end

function table.DeepCopy( obj )      
    local InTable = {};  
    local function Func(obj)  
        if type(obj) ~= "table" then   --判断表中是否有表  
            return obj;  
        end  
        local NewTable = {};  --定义一个新表  
        InTable[obj] = NewTable;  --若表中有表，则先把表给InTable，再用NewTable去接收内嵌的表  
        for k,v in pairs(obj) do  --把旧表的key和Value赋给新表  
            NewTable[Func(k)] = Func(v);  
        end  
        return setmetatable(NewTable, getmetatable(obj))--赋值元表  
    end  
    return Func(obj) --若表中有表，则把内嵌的表也复制了  
end  

function table.copy(source)
	local pool = {} 
	table.assign(source, pool)
	return pool
end

function table.assign(source, pool)
	source = source or {}
	pool = pool or {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			if pool[key] == nil then
				pool[key] = {}
			end
			table.assign(source[key], pool[key])
		else
			pool[key] = source[key]
		end
	end
end

function table.assign_over(source, pool)
   	source = source or {}
	pool = pool or {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			if pool[key] == nil then
				pool[key] = {}
			end
			table.assign(source[key], pool[key])
		else
            if pool[key] == nil then
			    pool[key] = source[key]
            end
		end
	end 
end

function table.show(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references

   -- (RiciLake) returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name

            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end

function table.sort_ext(tab, func)
   for i = 1, #tab do
      local max_index = i
      for j = i + 1, #tab do
         if func(tab[j], tab[max_index]) == true then
            max_index = j
         end
      end
      local tmp = tab[i]
      tab[i] = tab[max_index]
      tab[max_index] = tmp
   end
end

function table.count(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.value_type(t)
    for k, v in pairs(t) do
        return type(v)
    end
    return "nil"
end

function table.pairs_by_keys(t, f)
    f = f or function(x, y) return x < y end
    local a = {}
    for n in pairs(t) do 
        table.insert(a, n) 
    end
    table.sort(a, f)
    local i = 0                 -- iterator variable
    local iter = function ()    -- iterator function
        i = i + 1
        if a[i] == nil then 
            return nil
        else 
            return a[i], t[a[i]]
        end
    end
    return iter
end

function table.sort_by_keys(t, f)
	local value_type = table.value_type(t)
    if value_type == "table" then
        f = f or function(x, y) return x < y end
        for k, v in pairs(t) do
            v.__sort = k
        end
        table.sort(t, function(x, y)
            return f(x.__sort, y.__sort)
        end)
        for k, v in pairs(t) do
            v.__sort = nil
        end
    else
        error("table.sort_by_keys cannot compact with this value type %s", value_type)
    end
end

--slice array table
function table.slice( tab, from_index, to_index )
   if from_index < 1 or to_index > #tab or from_index < to_index then return end
   local result = {}
   for i = from_index, to_index, 1 do
      table.insert(result, tab[i])
   end
   return result
end

function table.has_value( tab, value )
    for _, v in pairs(tab) do
        if v == value then
            return true
        end
    end
    return false
end

function table.iterate2d(array, cb)
    for i=1, #array do
        for j=1, #array[i] do
            cb(i, j, array[i][j])
        end
    end
end

unpack = unpack or table.unpack