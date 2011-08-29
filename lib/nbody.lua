require('../res/colony-js');

local PI = 3.141592653589793;
local SOLAR__MASS = ((4 * PI) * PI);
local DAYS__PER__YEAR = 365.24;
local Body; Body = (_func(function (this, x, y, z, vx, vy, vz, mass)
this.x = x;
this.y = y;
this.z = z;
this.vx = vx;
this.vy = vy;
this.vz = vz;
this.mass = mass;
end));

(Body)[("prototype")].offsetMomentum = (_func(function (this, px, py, pz)
this.vx = (-px / SOLAR__MASS);
this.vy = (-py / SOLAR__MASS);
this.vz = (-pz / SOLAR__MASS);
return this;
end));
local Jupiter; Jupiter = (_func(function (this)
return _new(Body, 4.841431442464721, -1.1603200440274284, -0.10362204447112311, (0.001660076642744037 * DAYS__PER__YEAR), (0.007699011184197404 * DAYS__PER__YEAR), (-0.0000690460016972063 * DAYS__PER__YEAR), (0.0009547919384243266 * SOLAR__MASS));
end));

local Saturn; Saturn = (_func(function (this)
return _new(Body, 8.34336671824458, 4.124798564124305, -0.4035234171143214, (-0.002767425107268624 * DAYS__PER__YEAR), (0.004998528012349172 * DAYS__PER__YEAR), (0.000023041729757376393 * DAYS__PER__YEAR), (0.0002858859806661308 * SOLAR__MASS));
end));

local Uranus; Uranus = (_func(function (this)
return _new(Body, 12.894369562139131, -15.111151401698631, -0.22330757889265573, (0.002964601375647616 * DAYS__PER__YEAR), (0.0023784717395948095 * DAYS__PER__YEAR), (-0.000029658956854023756 * DAYS__PER__YEAR), (0.00004366244043351563 * SOLAR__MASS));
end));

local Neptune; Neptune = (_func(function (this)
return _new(Body, 15.379697114850917, -25.919314609987964, 0.17925877295037118, (0.0026806777249038932 * DAYS__PER__YEAR), (0.001628241700382423 * DAYS__PER__YEAR), (-0.00009515922545197159 * DAYS__PER__YEAR), (0.000051513890204661145 * SOLAR__MASS));
end));

local Sun; Sun = (_func(function (this)
return _new(Body, 0, 0, 0, 0, 0, 0, SOLAR__MASS);
end));

local NBodySystem; NBodySystem = (_func(function (this, bodies)
this.bodies = bodies;
local px = 0;
local py = 0;
local pz = 0;
local size = ((this)[("bodies")])[("length")];
local i = 0;
while (i < size) do
local b = ((this)[("bodies")])[i];
local m = (b)[("mass")];
px = _add(px, ((b)[("vx")] * m));
py = _add(py, ((b)[("vy")] * m));
pz = _add(pz, ((b)[("vz")] * m));
i = i + 1;
end
((this)[("bodies")])[0]:offsetMomentum(px, py, pz);
end));

(NBodySystem)[("prototype")].advance = (_func(function (this, dt)
local dx, dy, dz, distance, mag = nil, nil, nil, nil, nil;
local size = ((this)[("bodies")])[("length")];
local i = 0;
while (i < size) do
local bodyi = ((this)[("bodies")])[i];
local j = _add(i, 1);
while (j < size) do
local bodyj = ((this)[("bodies")])[j];
dx = ((bodyi)[("x")] - (bodyj)[("x")]);
dy = ((bodyi)[("y")] - (bodyj)[("y")]);
dz = ((bodyi)[("z")] - (bodyj)[("z")]);
distance = Math:sqrt(_add(_add((dx * dx), (dy * dy)), (dz * dz)));
mag = (dt / ((distance * distance) * distance));
bodyi.vx = ((bodyi)[("vx")] - ((dx * (bodyj)[("mass")]) * mag));
bodyi.vy = ((bodyi)[("vy")] - ((dy * (bodyj)[("mass")]) * mag));
bodyi.vz = ((bodyi)[("vz")] - ((dz * (bodyj)[("mass")]) * mag));
bodyj.vx = _add((bodyj)[("vx")], ((dx * (bodyi)[("mass")]) * mag));
bodyj.vy = _add((bodyj)[("vy")], ((dy * (bodyi)[("mass")]) * mag));
bodyj.vz = _add((bodyj)[("vz")], ((dz * (bodyi)[("mass")]) * mag));
j = j + 1;
end
i = i + 1;
end
local i = 0;
while (i < size) do
local body = ((this)[("bodies")])[i];
body.x = _add((body)[("x")], (dt * (body)[("vx")]));
body.y = _add((body)[("y")], (dt * (body)[("vy")]));
body.z = _add((body)[("z")], (dt * (body)[("vz")]));
i = i + 1;
end
end));
(NBodySystem)[("prototype")].energy = (_func(function (this)
local dx, dy, dz, distance = nil, nil, nil, nil;
local e = 0;
local size = ((this)[("bodies")])[("length")];
local i = 0;
while (i < size) do
local bodyi = ((this)[("bodies")])[i];
e = _add(e, ((0.5 * (bodyi)[("mass")]) * _add(_add(((bodyi)[("vx")] * (bodyi)[("vx")]), ((bodyi)[("vy")] * (bodyi)[("vy")])), ((bodyi)[("vz")] * (bodyi)[("vz")]))));
local j = _add(i, 1);
while (j < size) do
local bodyj = ((this)[("bodies")])[j];
dx = ((bodyi)[("x")] - (bodyj)[("x")]);
dy = ((bodyi)[("y")] - (bodyj)[("y")]);
dz = ((bodyi)[("z")] - (bodyj)[("z")]);
distance = Math:sqrt(_add(_add((dx * dx), (dy * dy)), (dz * dz)));
e = (e - (((bodyi)[("mass")] * (bodyj)[("mass")]) / distance));
j = j + 1;
end
i = i + 1;
end
return e;
end));
local n = 5000000;
local bodies = _new(NBodySystem, (Array)(this, (Sun)(this), (Jupiter)(this), (Saturn)(this), (Uranus)(this), (Neptune)(this)));
(print)(this, bodies:energy():toFixed(9));
local i = 0;
while (i < n) do
bodies:advance(0.01);
i = i + 1;
end
(print)(this, bodies:energy():toFixed(9));
