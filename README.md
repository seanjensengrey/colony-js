# Colony, a JavaScript-to-Lua Compiler

A simple JavaScript-to-Lua compiler.

## Requirements

CoffeeScript is required to run compiler.  
Lua requirements: Lua 5.1, the bitop package, and the "debug" library.

## Test

Run "coffee colonize.coffee demo/binarytrees.js > demo/binarytrees.lua".
Then "lua demo/binarytrees.lua"  

## Modules

Interop with other JavaScript modules works a la CommonJS with compiled JavaScript->Lua files.

Interop with Lua works with explicit invocation: function.call(arg0, arg1, arg2) for function calls, object.method(arg0, arg1) for method calls.

## License

Released under the MIT License.
