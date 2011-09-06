var json = require('dkjson')
print(json.encode.call(['Works:', 'Calling', 'a', 'Lua', 'library']).join(' '))

print(require('demo/luarequire2').apples)
