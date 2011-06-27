require('colony-js');

local i = 0;
while (i < 10) do
local _c = true; repeat
local _cont, _break, _e = {}, {}, nil
local _s, _r = xpcall(function ()
        if (i < 5) then
return _break;
end
(print)(this, i);
		return _cont
    end, function (err)
        _e = err
    end)
if _s == false then
    local e = _e;

end

if _r == _break then
break
end
if _r ~= _cont then
        return _r
end
until true;
_JS.void(((function () local _r = _JS.add(i, 1); i = _r; return _r end)() - 1));
if not _c then break end
end
