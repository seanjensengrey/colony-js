require('../res/colony-js');

local i = 0;
while _truthy((i < 5)) do
(print)(this, _add(("Level "), i));
i = i + 1;
local j = 0;
while _truthy((j < 5)) do
local _cpears = nil; repeat
(print)(this, _add(("J: "), j));
if _truthy((i == 3)) then
_capples = _cont; break;
end
j = j + 1;
until true;
if _cpears == _break  or _capples then break end
end
if _capples then break end

end

local i = 0;
while _truthy((i < 5)) do
local _c = nil; repeat
if _truthy((i % 2)) then
_c = _cont; break;
end
(print)(this, _add(("Even i: "), i));
until true;
i = i + 1;
if _c == _break  then break end
end
local i = 0;
while _truthy((i < 7)) do
local _ccandy = nil; repeat
i = i + 1;
local _cont, _break, _e = {}, {}, nil
local _s, _r = xpcall(function ()
        if _truthy((i == 3)) then
_ccandy = _cont; return _break;
end
(print)(this, _add(("i="), i));
if _truthy((i == 5)) then
error(("Some error when i == 5"));
end
		return _cont
    end, function (err)
        _e = err
    end)
if _s == false then
    local e = _e;
(print)(this, _add(("Error: "), e));

elseif _r == _break then
break
elseif _r ~= _cont then
        return _r
end
(print)(this, ("Incrementing..."));
until true;
if _ccandy == _break  then break end
end

