require('colony-js');

local _S; _S = (function (this, ...)
local arguments = _JS.arr((function (...) return arg; end)(...));
local b, c, d = ...;
(print)(this, (arguments)[("length")]);
(print)(this, b);
if (b ~= 6) then
(_S)(this, 6, 6, 6);
end
end);

(_S)(this, 5, 6, 7, 8, 9);
