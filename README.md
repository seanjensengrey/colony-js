# Colony, a JavaScript-to-Lua Compiler

Colony compiles JavaScript to Lua 5.1-compatible code, using a small support library. Colony is compatible with Lua in use in extensions and as a standalone language.

## What it does

Colony lets you use the Lua runtime with JS's familiar syntax. Let's start with the hello world example:

    print(["Hello", "world."].concat(["Welcome", "to", "colony"]).join(" "))

Compiled with Colony to Lua:

    local _JS = require('../colony-js');
    local string, math = nil, nil;
    local this, Object, Array, String, Math, require, print = _JS.this, _JS.Object, _JS.Array, _JS.String, _JS.Math, _JS.require, _JS.print;
    local _exports = {}; local exports = _exports;
    
    (print)(this, _JS._arr({[0]=("Hello"), ("world.")}):concat(_JS._arr({[0]=("Welcome"), ("to"), ("colony")})):join((" ")));
    
    return _exports;

Verbose! But let's break down the output: the first segment loads `colony-js.lua`, our JavaScript support library. Then we set up our global aliases to Java constructors and our `exports` object. The next segment is our translated code: we use the JavaScript built-in `print` function (with an implicit `this` variable), construct a few 0-indexed arrays, concatenate and join just as we could in Lua. 

This works with much larger examples, provided in the `demo/` directory.

## Getting Started

Ensure CoffeeScript and Lua are both installed on the commandline.  

    git clone git://github.com/timcameronryan/colony-js.git
    cd colony-js
    coffee colonize.coffee demo/binarytrees.js > demo/binarytrees.lua
    lua -e 'package.path=package.path..";lib/?.lua"' demo/binarytrees.lua

## Requirements

For the compiler:

* CoffeeScript runtime is required to run the compiler.
* Lua 5.1, the bitop package, and the "debug" library are required to run Colony-compiled scripts.

For compiled code:

* "lib/colony-js.lua" is a required library for all compiled scripts.

## JavaScript and Lua Interop

Interop with other JavaScript modules works a la CommonJS through the `require` function (which adopts the semantics of the corresponding Lua function).

Interop between JavaScript and Lua works with some caveats:

* Function calls in JavaScript pass the `this` object as the first parameter. To call a native Lua function from JavaScript, pass your first argument as the `this` parameter: `func.call(arg0, arg1, arg2)`
* `object.method(arg0, arg1)` in JavaScript maps to `object:method(arg0, arg1)` in Lua.
* *NOTE:* Colony uses the debug library to replace the metatables of functions, strings, booleans, and numbers. The latter two do not usually have metatables at all, and should not cause conflicts. Lua modules required by Colony that expect the `string` object to be the metatable of string literals (eg. `("apples"):len()`) will break. The workaround is to ensure all included code uses the methods of the native `string` object (eg. `string.len("apples")`)

## License

Copyright (c) 2011. Released under the MIT License.
