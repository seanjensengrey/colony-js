require('colony-js');

local a = nil;
(print)(this, ("Let's do somethng cool here."));
a = (function (this, args)
local x, _i, _len, _results = nil, nil, nil, nil;
_results = _JS.arr({});
_JS.void(({(function () local _r = 0; _i = _r; return _r end)(), (function () local _r = (args).length; _len = _r; return _r end)()})[2]);
while (_i < _len) do
x = (args)[_i];
_results:push((print)(this, x));
_JS.void(((function () local _r = _JS.add(_i, 1); _i = _r; return _r end)() - 1));
end
return _results;
end);
(a)(this, _JS.arr({[0]=5, 6, 7}));
