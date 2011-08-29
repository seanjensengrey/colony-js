require('../res/colony-js');

local fastaRepeat; fastaRepeat = (_func(function (this, n, seq)
local seqi = 0; local len = (seq)[("length")]; local i = nil; local j = nil; local k = nil; local l = nil; local block = nil; local str = (Array)(this, _add((len * 60), 1)):join(seq); local lines = (Array)(this, (function () local _r = (function () local _r = (len * len); j = _r; return _r end)(); i = _r; return _r end)());

while ((function () local _r = j; j = j + -1; return _r end)() > -1) do
lines[j] = str:substr((60 * j), 60);
end

block = lines:join(("\n"));
j = 0;
k = Math:floor(((function () local _r = Math:floor((n / 60)); l = _r; return _r end)() / i));
while (j < k) do
(print)(this, block);
j = j + 1;
end
j = 0;
k = (l % i);
while (j < k) do
(print)(this, (lines)[j]);
j = j + 1;
end
if _truthy(((n % 60) > 0)) then
(print)(this, (lines)[k]:substr(0, (n % 60)));
end
end));

local rand = ((_func(function (this)
local Last = 42;

return (_func(function (this)
return ((function () local _r = (_add((Last * 3877), 29573) % 139968); Last = _r; return _r end)() / 139968);
end));
end)))(this);

local printLineMaker; printLineMaker = (_func(function (this, table)
local h = 0; local k = _arr({}); local v = _arr({}); local c = nil; local l = 0;

for c,_v in pairs(table) do
l = (function () local _r = (function () local _r = _add((table)[(function () local _r = c; k[(function () h = h + 1; return h end)()] = _r; return _r end)()], l); table[(function () local _r = c; k[(function () h = h + 1; return h end)()] = _r; return _r end)()] = _r; return _r end)(); v[h] = _r; return _r end)();
end
return (_func(function (this, x)
local line = ("");

local i = 0;
while (i < x) do
local _cnext = nil; repeat
local r = (rand)(this); local j = 0;

while _truthy(true) do
local _c = nil; repeat
if _truthy((r < (v)[j])) then
line = _add(line, (k)[j]);
_cnext = _cont; break;
end
until true;
j = j + 1;
if _c == _break  or next then break end
end
until true;
i = i + 1;
if _cnext == _break  then break end
end
(print)(this, line);
end));
end));

local fastaRandom; fastaRandom = (_func(function (this, n, table)
local printLine = (printLineMaker)(this, table);

while ((function () local _r = (n - 60); n = _r; return _r end)() > -1) do
(printLine)(this, 60);
end

if _truthy(((n < 0) and (n > -60))) then
(printLine)(this, _add(60, n));
end
end));

(_func(function (this, n)
local ALU = _add(_add(_add(_add(_add(_add(("GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"), ("GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA")), ("CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT")), ("ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA")), ("GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG")), ("AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC")), ("AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"));

local IUB = _object({["a"]=0.27, ["c"]=0.12, ["g"]=0.12, ["t"]=0.27, ["B"]=0.02, ["D"]=0.02, ["H"]=0.02, ["K"]=0.02, ["M"]=0.02, ["N"]=0.02, ["R"]=0.02, ["S"]=0.02, ["V"]=0.02, ["W"]=0.02, ["Y"]=0.02});

local HomoSap = _object({["a"]=0.302954942668, ["c"]=0.1979883004921, ["g"]=0.1975473066391, ["t"]=0.3015094502008});

(print)(this, (">ONE Homo sapiens alu"));
(fastaRepeat)(this, (2 * n), ALU);
(print)(this, (">TWO IUB ambiguity codes"));
(fastaRandom)(this, (3 * n), IUB);
(print)(this, (">THREE Homo sapiens frequency"));
(fastaRandom)(this, (5 * n), HomoSap);
end)):call(this, ((1 * 25000) * 1));
