require('../res/colony-js');

local fannkuch; fannkuch = (function (this, n)
local p, q, s = (Array)(this, n), (Array)(this, n), (Array)(this, n);
local sign, maxflips, sum, m = 1, 0, 0, (n - 1);
local i = 0;
while _truthy((i < n)) do
p[i] = i;
q[i] = i;
s[i] = i;
i = i + 1;
end
repeat
local q0 = (p)[0];
if _truthy((q0 ~= 0)) then
local i = 1;
while _truthy((i < n)) do
q[i] = (p)[i];
i = i + 1;
end
local flips = 1;
repeat
local qq = (q)[q0];
if _truthy((qq == 0)) then
sum = _add(sum, (sign * flips));
if _truthy((flips > maxflips)) then
maxflips = flips;
end
_c = _break; break;
end
q[q0] = q0;
if _truthy((q0 >= 3)) then
local i, j, t = 1, (q0 - 1), nil;
repeat
t = (q)[i];
q[i] = (q)[j];
q[j] = t;
i = i + 1;
j = j + -1;
until not _truthy((i < j));
end
q0 = qq;
flips = flips + 1;
until not _truthy(true);
end
if _truthy((sign == 1)) then
local t = (p)[1];
p[1] = (p)[0];
p[0] = t;
sign = -1;
else
local t = (p)[1];
p[1] = (p)[2];
p[2] = t;
sign = 1;
local i = 2;
while _truthy((i < n)) do
local sx = (s)[i];
if _truthy((sx ~= 0)) then
s[i] = (sx - 1);
_c = _break; break;
end
if _truthy((i == m)) then
return (Array)(this, sum, maxflips);
end
s[i] = i;
t = (p)[0];
local j = 0;
while _truthy((j <= i)) do
p[j] = (p)[_add(j, 1)];
j = j + 1;
end
p[_add(i, 1)] = t;
i = i + 1;
end
end
until not _truthy(true);
end);

local n = ((1 * 10) * 1);
local pf = (fannkuch)(this, n);
(print)(this, _add(_add(_add(_add(_add((pf)[0], ("\n")), ("Pfannkuchen(")), n), (") = ")), (pf)[1]));
