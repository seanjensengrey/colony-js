--[[
References:
  https://github.com/mirven/underscore.lua/blob/master/lib/underscore.lua
  https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String/slice
]]--

if not _JS then

require('bit')

-- global object to prevent conflicts

_JS = {}

-- void function for expression statements (which lua disallows)

_void = function () end

-- null object (nil is "undefined")

_null = {}

-- "add" function to rectify lua's distinction of adding vs concatenation

_add = function (a, b)
	if type(a) == "string" or type(b) == "string" then
		return a .. b
	else
		return a + b
	end
end

-- typeof operator

_typeof = type

-- debug.setmetatable to give all functions a prototype

_func_proto = {}
_luafunctor = function (f)
	return (function (this, ...) return f(...) end)
end
debug.setmetatable((function () end), {
	__index=function (t, p)
		if getmetatable(t)[t] and getmetatable(t)[t][p] ~= nil then
			return getmetatable(t)[t][p]
		end
		return _func_proto[p]
	end,
	__newindex=function (t, p, v)
		local pt = getmetatable(t)[t] or {}
		pt[p] = v
		getmetatable(t)[t] = pt
	end
})

-- function constructor

_func = function (f)
	f.prototype = {}
	return f
end

-- object prototype and constructor

_obj_proto = {}
_object = function (o)
	local mt = getmetatable(o) or {}
	mt.__index = _obj_proto
	setmetatable(o, mt)
	return o
end
_object(_func_proto)

-- debug.setmetatable to give all numbers a prototype

_num_proto = _object({})
debug.setmetatable(0, {__index=_num_proto})

-- debug.setmetatable to give all booleans a prototype

_bool_proto = _object({})
debug.setmetatable(true, {__index=_bool_proto})

-- give all strings a prototype

_str_proto = _object({})
_rawstring = string
getmetatable("").__index = function (str, p)
	if (p == "length") then
		return string.len(str)
	elseif (tonumber(p) == p) then
		return _rawstring.sub(str, p+1, p+1)
	else
		return _str_proto[p]
	end
end

-- array prototype and constructor

_arr_proto = _object({})
_arr_mt = {
	__index = function (arr, p)
	  if (p == "length") then
		if arr[0] then return table.getn(arr) + 1 end
		return table.getn(arr)
	  else
		return _arr_proto[p]
	  end
	end
}
_arr = function (a)
	setmetatable(a, _arr_mt)
	return a
end

-- "new" invocation

_new = function (f, ...)
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

_num_proto.toFixed = function (num, n)
	return tostring(num)
end

-- string prototype

_str_proto.charCodeAt = function (str, i, a)
	return string.byte(str, i+1)
end
_str_proto.charAt = function (str, i)
	return string.sub(str, i+1, i+1)
end
_str_proto.substr = function (str, i)
	return string.sub(str, i+1)
end
_str_proto.toLowerCase = function (str)
	return string.lower(str)
end
_str_proto.toUpperCase = function (str)
	return string.upper(str)
end
_str_proto.indexOf = function (str, needle)
	local ret = string.find(str, needle, 1, true) 
	if ret == null then return -1; else return ret - 1; end
end

-- object prototype

_obj_proto.hasInstance = function (ths, p)
	return toboolean(rawget(ths, p))
end

-- function prototype

_func_proto.call = function (func, ths, ...)
	return func(ths, ...)
end
_func_proto.apply = function (func, ths, args)
	-- copy args to new args array
	local luargs = {}
	for i=0,args.length-1 do luargs[i+1] = args[i] end
	return func(ths, unpack(luargs))
end

-- array prototype

_arr_proto.push = function (ths, elem)
	return table.insert(ths, ths.length, elem)
end
_arr_proto.pop = function (ths)
	return table.remove(ths, ths.length-1)
end
_arr_proto.shift = function (ths)
	local ret = ths[0]
	ths[0] = table.remove(ths, 0)
	return ret
end
_arr_proto.unshift = function (ths, elem)
	return table.insert(ths, 0, elem)
end
_arr_proto.reverse = function (ths)
	local arr = _arr({})
	for i=0,ths.length-1 do
		arr[ths.length - 1 - i] = ths[i]
	end
	return arr
end
_arr_proto.slice = function (ths, len)
	local arr = _arr({})
	for i=len,ths.length-1 do
		arr:push(ths[i])
	end
	return arr
end
_arr_proto.concat = function (src1, src2)
	local arr = _arr({})
	for i=0,src1.length-1 do
		arr.push(src1[i])
	end
	for i=0,src2.length-1 do
		arr.push(src2[i])
	end
	return arr
end
_arr_proto.join = function (ths, str)
	local _r = ""
	for i=0,ths.length-1 do
		if not ths[i] or ths[i] == _null then _r = _r .. str
		else _r = _r .. ths[i] .. str end
	end
	return _rawstring.sub(ths, 1, string.len(_r) - string.len(str))
end

--[[
Globals
]]--

_global = _G

-- Object

Object = {}
Object.prototype = _obj_proto

-- Array

Array = _luafunctor(function (one, ...)
	if #arg > 0 then
		arg[0] = one
		return _arr(arg)
	elseif one ~= nil then
		local a = {}
		for i=0,one-1 do a[i]=_null end
		return _arr(a)
	end
	return _arr({})
end)
Array.prototype = _arr_proto
Array.isArray = _luafunctor(function (arr)
	return (getmetatable(arr) or {}) == _arr_mt
end)

-- String

String = _luafunctor(function (str)
	return tostring(str)
end)
String.prototype = _str_proto
String.fromCharCode = _luafunctor(function (c)
	return _rawstring.char(c)
end)

-- Math

_rawmath = math
Math = _object({
	max = _luafunctor(_rawmath.max),
	sqrt = _luafunctor(_rawmath.sqrt)
})

-- Print

_rawprint = print
print = _luafunctor(function (x)
	if x == nil then 
		_rawprint("undefined")
	elseif x == _null then
		_rawprint("null")
	else
		_rawprint(x)
	end
end)

-- setup default "this" object

this = _global

-- break/cont flags

_break = {}; _cont = {}

-- truthy values

function _truthy(o)
	return o and o ~= 0 and o ~= ""
end

-- require function

_require = require
require = _luafunctor(_require)

-- exports object

_exports = {}
exports = _exports

end
