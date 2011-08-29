require('../res/colony-js');

local A; A = (function (this, i, j)
return (1 / _add(_add(((_add(i, j) * _add(_add(i, j), 1)) / 2), i), 1));
end);

local Au; Au = (function (this, u, v)
local i = 0;
while (i < (u)[("length")]) do
local t = 0;
local j = 0;
while (j < (u)[("length")]) do
t = _add(t, ((A)(this, i, j) * (u)[j]));
j = j + 1;
end
v[i] = t;
i = i + 1;
end
end);

local Atu; Atu = (function (this, u, v)
local i = 0;
while (i < (u)[("length")]) do
local t = 0;
local j = 0;
while (j < (u)[("length")]) do
t = _add(t, ((A)(this, j, i) * (u)[j]));
j = j + 1;
end
v[i] = t;
i = i + 1;
end
end);

local AtAu; AtAu = (function (this, u, v, w)
(Au)(this, u, w);
(Atu)(this, w, v);
end);

local spectralnorm; spectralnorm = (function (this, n)
local i, u, v, w, vv, vBv = nil, _arr({}), _arr({}), _arr({}), 0, 0;
i = 0;
while (i < n) do
u[i] = 1;
v[i] = (function () local _r = 0; w[i] = _r; return _r end)();
i = i + 1;
end
i = 0;
while (i < 10) do
(AtAu)(this, u, v, w);
(AtAu)(this, v, u, w);
i = i + 1;
end
i = 0;
while (i < n) do
vBv = _add(vBv, ((u)[i] * (v)[i]));
vv = _add(vv, ((v)[i] * (v)[i]));
i = i + 1;
end
return Math:sqrt((vBv / vv));
end);

(print)(this, (spectralnorm)(this, 500):toFixed(9));
