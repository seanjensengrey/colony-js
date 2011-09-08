# Colony, a JavaScript-to-Lua Compiler

Colony compiles JavaScript to Lua 5.1-compatible code, using a small support library. Colony is compatible with Lua in use in extensions and as a standalone language.

## What it does

Colony lets you use the Lua runtime with JS's familiar syntax. Let's start with the hello world example:

    print(["Hello", "world."].concat(["Welcome", "to", "colony"]).join(" "))

Compiled with Colony to Lua:

    local _JS = require('colony-js');
    local string, math = nil, nil;
    local this, Object, Array, String, Math, require, print = _JS.this, _JS.Object, _JS.Array, _JS.String, _JS.Math, _JS.require, _JS.print;
    local _exports = {}; local exports = _exports;
    
    (print)(this, _JS._arr({[0]=("Hello"), ("world.")}):concat(_JS._arr({[0]=("Welcome"), ("to"), ("colony")})):join((" ")));
    
    return _exports;

Verbose? Let's break down the output: the first segment loads `colony-js.lua`, our JavaScript support library. Then we set up our global aliases to Java constructors and our `exports` object. The next segment is our translated code: we use the JavaScript built-in `print` function (with an implicit `this` variable), construct a few 0-indexed arrays, concatenate and join just as we could in Lua. 

This works with much larger examples, provided in the `demo/` directory.

## Getting Started

Ensure CoffeeScript and Lua 5.1.x are both installed on the commandline.  

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

## JavaScript Interop

Interop with other JavaScript modules works a la CommonJS through the global `require` function. Note that any JavaScript modules that are required must also have been compiled with colony to Lua.

## Lua Interop

Interop between JavaScript and Lua works seamlessly, with some minor caveats for function invocation:

* JavaScript methods compiled to Lua have an implicit `this` argument as the first parameter. Lua functions which call JavaScript function should pass a `this` object (which may be null) as the first parameter. Inversely, JavaScript calling Lua must pass the first argument as the `this` parameter; the most logical way to do this is using the `.call()` method: `func.call(arg0, arg1, arg2)`
* `object.method(arg0, arg1)` in JavaScript maps to `object:method(arg0, arg1)` in Lua.

*NOTE:* Colony uses the debug library to replace the intrinsic metatables of functions, strings, booleans, and numbers. This probably will not cause issues (functions, booleans, and numbers in Lua have no default metatables), except if a Lua module expects the built-in `string` object to be the metatable of string literals (eg. `("apples"):len()`). The workaround is to ensure all included code explicitly calls the methods of the `string` object (eg. `string.len("apples")`)

## License

Copyright (c) 2011. Released under the MIT License.
