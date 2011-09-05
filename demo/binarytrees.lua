(_require or require)('../colony-js');

local TreeNode; TreeNode = (_func(function (this, left, right, item)
this.left = left;
this.right = right;
this.item = item;
end));

(TreeNode)[("prototype")].itemCheck = (_func(function (this)
if _truthy(((this)[("left")] == _null)) then
return (this)[("item")];
else
return (_add((this)[("item")], (this)[("left")]:itemCheck()) - (this)[("right")]:itemCheck());
end
end));
local bottomUpTree; bottomUpTree = (_func(function (this, item, depth)
local bottomUpTree = debug.getinfo(1, 'f').func;
if _truthy((depth > 0)) then
return _new(TreeNode, (bottomUpTree)(this, ((2 * item) - 1), (depth - 1)), (bottomUpTree)(this, (2 * item), (depth - 1)), item);
else
return _new(TreeNode, _null, _null, item);
end
end));

local minDepth = 4;

local n = 16;

local maxDepth = Math:max(_add(minDepth, 2), n);

local stretchDepth = _add(maxDepth, 1);

local check = (bottomUpTree)(this, 0, stretchDepth):itemCheck();

(print)(this, _add(_add(_add(("stretch tree of depth "), stretchDepth), ("\t check: ")), check));
local longLivedTree = (bottomUpTree)(this, 0, maxDepth);

local depth = minDepth;
while (depth <= maxDepth) do
local iterations = bit.lshift(1, _add((maxDepth - depth), minDepth));

check = 0;
local i = 1;
while (i <= iterations) do
check = _add(check, (bottomUpTree)(this, i, depth):itemCheck());
check = _add(check, (bottomUpTree)(this, -i, depth):itemCheck());
i = i + 1;
end
(print)(this, _add(_add(_add(_add((iterations * 2), ("\t trees of depth ")), depth), ("\t check: ")), check));
depth = _add(depth, 2);
end
(print)(this, _add(_add(_add(("long lived tree of depth "), maxDepth), ("\t check: ")), longLivedTree:itemCheck()));

return _exports;
