# Colony, a JavaScript-to-Lua Compiler

Colony compiles JavaScript to Lua 5.1-compatible code, using a small support library. Colony is compatible with Lua in use as extensions and as a standalone language.

## Requirements

CoffeeScript runtime is required to run the compiler.  
Lua 5.1, the bitop package, and the "debug" library are required to run Colony-compiled scripts.  
"colony-js.lua" is required for all compiled scripts.

## Demo

Ensure CoffeeScript and Lua are both installed on the commandline.  
Run "coffee colonize.coffee demo/binarytrees.js > demo/binarytrees.lua".  
Then "lua demo/binarytrees.lua".

## Modules

Interop with other JavaScript modules works a la CommonJS with compiled JavaScript->Lua files.

Interop with Lua works with explicit invocation: function.call(arg0, arg1, arg2) for function calls, object.method(arg0, arg1) for method calls.

## License

Released under the MIT License.
