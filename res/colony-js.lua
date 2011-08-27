--[[
References:
  https://github.com/mirven/underscore.lua/blob/master/lib/underscore.lua
  https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String/slice
]]--

require('bit')

-- global object to prevent conflicts

_JS = {}

-- void function for expression statements (which lua disallows)

_JS.void = function () end

-- null object (different from undefined)

_JS.null = {}

-- "add" function to rectify lua's distinction of adding vs concatenation

_JS.add = function (a, b)
	if type(a) == "string" or type(b) == "string" then
		return a .. b
	else
		return a + b
	end
end

-- typeof operator

_JS.typeof = type

-- debug.setmetatable to give all functions a prototype

_JS.func_proto = {}
_JS.luafunctor = function (f)
	return (function (this, ...) return f(...) end)
end
debug.setmetatable((function () end), {
	__index=function (t, p)
		if getmetatable(t)[t] and getmetatable(t)[t][p] ~= nil then
			return getmetatable(t)[t][p]
		end
		return _JS.func_proto[p]
	end,
	__newindex=function (t, p, v)
		local pt = getmetatable(t)[t] or {}
		pt[p] = v
		getmetatable(t)[t] = pt
	end
})

-- object prototype and constructor

_JS.obj_proto = {}
_JS.object = function (o)
	local mt = getmetatable(o) or {}
	mt.__index = _JS.obj_proto
	setmetatable(o, mt)
	return o
end
_JS.object(_JS.func_proto)

-- debug.setmetatable to give all numbers a prototype

_JS.num_proto = _JS.object({})
debug.setmetatable(0, {__index=_JS.num_proto})

-- debug.setmetatable to give all booleans a prototype

_JS.bool_proto = _JS.object({})
debug.setmetatable(true, {__index=_JS.bool_proto})

-- give all strings a prototype

_JS.str_proto = _JS.object({})
_JS.rawstring = string
getmetatable("").__index = function (str, p)
	if (p == "length") then
		return string.len(str)
	elseif (tonumber(p) == p) then
		return _JS.rawstring.sub(str, p+1, p+1)
	else
		return _JS.str_proto[p]
	end
end

-- array prototype and constructor

_JS.arr_proto = _JS.object({})
_JS.arr_mt = {
	__index = function (arr, p)
	  if (p == "length") then
		if arr[0] then return table.getn(arr) + 1 end
		return table.getn(arr)
	  else
		return _JS.arr_proto[p]
	  end
	end
}
_JS.arr = function (a)
	setmetatable(a, _JS.arr_mt)
	return a
end

-- "new" invocation

_JS.new = function (f, ...)
	local o = {}
	setmetatable(o, {__index=f.prototype})
	local r = f(o, ...)
	if r then return r end
	return o
end

--[[
Standard Library
]]--

-- number prototype

_JS.num_proto.toFixed = function (num, n)
	return tostring(num)
end

-- string prototype

_JS.str_proto.charCodeAt = function (str, i, a)
	return string.byte(str, i+1)
end
_JS.str_proto.charAt = function (str, i)
	return string.sub(str, i+1, i+1)
end
_JS.str_proto.substr = function (str, i)
	return string.sub(str, i+1)
end
_JS.str_proto.toLowerCase = function (str)
	return string.lower(str)
end
_JS.str_proto.toUpperCase = function (str)
	return string.upper(str)
end
_JS.str_proto.indexOf = function (str, needle)
	local ret = string.find(str, needle, 1, true) 
	if ret == null then return -1; else return ret - 1; end
end

-- object prototype

_JS.obj_proto.hasInstance = function (ths, p)
	return toboolean(rawget(ths, p))
end

-- function prototype

_JS.func_proto.call = function (func, ths, ...)
	return func(ths, ...)
end
_JS.func_proto.apply = function (func, ths, args)
	-- copy args to new args array
	local luargs = {}
	for i=0,args.length-1 do luargs[i+1] = args[i] end
	return func(ths, unpack(luargs))
end

-- array prototype

_JS.arr_proto.push = function (ths, elem)
	return table.insert(ths, ths.length, elem)
end
_JS.arr_proto.pop = function (ths)
	return table.remove(ths, ths.length-1)
end
_JS.arr_proto.shift = function (ths)
	local ret = ths[0]
	ths[0] = table.remove(ths, 0)
	return ret
end
_JS.arr_proto.unshift = function (ths, elem)
	return table.insert(ths, 0, elem)
end
_JS.arr_proto.reverse = function (ths)
	local arr = _JS.arr({})
	for i=0,ths.length-1 do
		arr[ths.length - 1 - i] = ths[i]
	end
	return arr
end
_JS.arr_proto.slice = function (ths, len)
	local arr = _JS.arr({})
	for i=len,ths.length-1 do
		arr:push(ths[i])
	end
	return arr
end
_JS.arr_proto.concat = function (src1, src2)
	local arr = _JS.arr({})
	for i=0,src1.length-1 do
		arr.push(src1[i])
	end
	for i=0,src2.length-1 do
		arr.push(src2[i])
	end
	return arr
end

--[[
Globals
]]--

_JS.global = _G

-- Object

Object = {}
Object.prototype = _JS.obj_proto

-- Array

Array = _JS.luafunctor(function (one, ...)
	if #arg > 0 then
		arg[0] = one
		return _JS.arr(arg)
	elseif one ~= nil then
		local a = {}
		for i=0,one-1 do a[i]=_JS.null end
		return _JS.arr(a)
	end
	return _JS.arr({})
end)
Array.prototype = _JS.arr_proto
Array.isArray = _JS.luafunctor(function (arr)
	return (getmetatable(arr) or {}) == _JS.arr_mt
end)

-- String

String = _JS.luafunctor(function (str)
	return tostring(str)
end)
String.prototype = _JS.str_proto
String.fromCharCode = _JS.luafunctor(function (c)
	return _JS.rawstring.char(c)
end)

-- Math

_JS.rawmath = math
Math = _JS.object({
	max = _JS.luafunctor(_JS.rawmath.max),
	sqrt = _JS.luafunctor(_JS.rawmath.sqrt)
})

-- Print

_JS.rawprint = print
print = _JS.luafunctor(function (x)
	if x == nil then 
		_JS.rawprint("undefined")
	elseif x == _JS.null then
		_JS.rawprint("null")
	else
		_JS.rawprint(x)
	end
end)

-- setup default "this" object

this = _JS.global
