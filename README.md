# Colony, a JavaScript-to-Lua Compiler

Colony compiles JavaScript to Lua 5.1-compatible code, using a small support library. Colony can be used in any Lua application supporting the debug library (enabled in Lua 5.1 by default).

*Colony is alpha-quality.* It will run all of the examples in the `demo/` directory, but still requires development to fully support ECMAScript 5 or support large codebases (like colony itself). If you're interested in its development, contact me by email.

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

For compiled code:

* "lib/colony-js.lua" is a required library for all compiled scripts.
* Lua 5.1, the `bitop` package, and the "debug" library are required to run Colony-compiled scripts.

## JavaScript (Colony) Interop

Interop with other JavaScript modules works a la CommonJS through the global `require` function. Note that any JavaScript modules that are required must also have been compiled with colony to Lua.

## Lua Interop

Interop between JavaScript and Lua works seamlessly, as Colony compiles to pure Lua code. Be aware of language caveats:

1. JavaScript methods compiled to Lua have an implicit `this` argument as the first parameter.
    * Lua functions which call JavaScript function should pass a `this` object (which may be null) as the first parameter.
    * Inversely, JavaScript calling Lua must pass the first argument as the `this` parameter; the most logical way to do this is using the `.call()` method: `func.call(arg0, arg1, arg2)`
    * `object.method(arg0, arg1)` in JavaScript maps to `object:method(arg0, arg1)` in Lua.
1. Arrays in JavaScript are indexed from 0, and Lua arrays are indexed from 1. Make sure to either push a dummy element using `.shift()` when calling Lua from JavaScript, and to explicitly assign the first array element in Lua to the 0 index (eg. `{[0]='first element', 'second element', 'third...'}`)

*NOTE:* Colony uses the debug library to replace the intrinsic metatables of functions, strings, booleans, and numbers. This probably will not cause issues (functions, booleans, and numbers in Lua have no default metatables), except if a Lua module expects the built-in `string` object to be the metatable of string literals (eg. `("apples"):len()`). The workaround is to ensure all included code explicitly calls the methods of the `string` object (eg. `string.len("apples")`). Unfortunately, this limitation extends to all code that runs in conjunction with Colony scripts (for now).

## Roadmap

Rough guidelines that will be followed when development continues.

1. Complete ECMAScript 5 support
1. Become self-hosting
1. Enable easier sharing between JavaScript/Lua modules.
1. Avoid the overriding of built-in metatables using the `debug` library (if possible)

## License

Copyright (c) 2011. Released under the MIT License. `parser-base.js` courtesy UglifyJS.
