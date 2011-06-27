local print = print

function a()
print('hi')
end

local pprint = print
print = function () pprint('NOPERS') end

a()
