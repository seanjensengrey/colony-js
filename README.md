# Colony, a JavaScript-to-Lua Compiler

Colony compiles JavaScript to Lua 5.1-compatible code, using a small support library. Colony is compatible with Lua in use as extensions and as a standalone language.

## What it does

Colony lets you use an embedded language with a familiar syntax. Let's start with the hello world example:

    print(["Hello", "world."].concat(["Welcome", "to", "colony"]).join(" "))

Compiled with Colony to Lua:

    (_require or require)('../colony-js');
    
    (print)(this, _arr({[0]=("Hello"), ("world.")}):concat(_arr({[0]=("Welcome"), ("to"), ("colony")})):join((" ")));
    
    return _exports; 

The resulting code is more verbose; but, we have the benefits of having an implicit `this` object, 0-based indexing for arrays, and the familiarity of JavaScript builtin libraries.

## Getting Started

Ensure CoffeeScript and Lua are both installed on the commandline.  

    git clone git://github.com/timcameronryan/colony-js.git
    cd colony-js
    coffee colonize.coffee demo/binarytrees.js > demo/binarytrees.lua
    lua demo/binarytrees.lua

## Requirements

CoffeeScript runtime is required to run the compiler.  
Lua 5.1, the bitop package, and the "debug" library are required to run Colony-compiled scripts.  
"colony-js.lua" is required for all compiled scripts.

## JavaScript and Lua Interop

Interop with other JavaScript modules works a la CommonJS with compiled JavaScript->Lua files.

Interop with Lua works with explicit invocation: function.call(arg0, arg1, arg2) for function calls, object.method(arg0, arg1) for method calls.

## License

Released under the MIT License.
