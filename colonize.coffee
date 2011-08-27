parser = require('./parser')
ast = require('./ast')
fs = require('fs')

# detects if "continue" is used in the current loop

usesContinue = (stat) ->
	continueWalker = (o) ->
		switch o?[0]
			when "while-stat", "do-while-stat", "for-stat", "for-in-stat", "label-stat", "closure-context"
				return []
			when "continue-stat"
				return [true]
			else
				return ast.walk(o, continueWalker)

	return continueWalker(stat).length > 0

fixRef = (str) ->
	return str.replace(/_/g, '__').replace(/\$/g, '_S')

isSafe = (str) ->
	return str.indexOf("_") != -1

#
# luize function
# 

loops = []

colonize = (o) ->
	return "" if not o

	switch o[0]

		# contexts

		when "script-context"
			[_, ln, stats] = o
			return (luize(stat) for stat in stats).join('\n')
		when "closure-context"
			[_, ln, name, args, stats] = o

			# fix references
			name = fixRef(name) if name; args = (fixRef(x) for x in args)

			# name argument only when necessary
			namestr = ""
			if name in ast.undeclaredRefs(o)
				namestr = "local #{name} = debug.getinfo(1, 'f').func;\n"

			loopsbkp = loops
			loops = []
			if ast.usesArguments(o)
				ret = "function (this, ...)\n" + namestr +
					"local arguments = _JS.arr((function (...) return arg; end)(...));\n" +
					(if args.length
						"local #{args.join(', ')} = ...;\n"
					else "") +
					(luize(x) for x in stats).join('\n') + "\n" +
					"end"
			else
				ret = "function (#{['this'].concat(args).join(', ')})\n" + namestr +
					(luize(x) for x in stats).join('\n') + "\n" +
					"end"
			loops = loopsbkp
			return ret

		# literals

		when "num-literal"
			[_, ln, value] = o
			return value
		when "str-literal"
			[_, ln, value] = o
			return "(\"#{value}\")"
		when "obj-literal"
			[_, ln, props] = o
			values = ("[\"#{k.replace('\"', '\\\"')}\"]=#{luize(v)}" for [k, v] in props)
			return "_JS.object({#{values.join(', ')}})"
		when "array-literal"
			[_, ln, exprs] = o
			return "_JS.arr({})" unless exprs.length
			return "_JS.arr({[0]=" + [luize(exprs[0])].concat(luize(x) for x in exprs.slice(1)).join(', ') + "})"
		when "undef-literal"
			return "nil"
		when "null-literal"
			return "_JS.null"
		when "boolean-literal"
			[_, ln, value] = o
			return if value then "true" else "false"
			return value
		when "func-literal"
			[_, ln, closure] = o
			return "(" + luize(closure) + ")"
		#when "regexp-literal"
		#	[_, ln, expr, flags] = o

		# operations

		when "and-op-expr", "or-op-expr", "eq-op-expr", "neq-op-expr", "eqs-op-expr", "neqs-op-expr", "sub-op-expr", "mul-op-expr", "div-op-expr", "mod-op-expr", "lt-op-expr", "lte-op-expr", "gt-op-expr", "gte-op-expr"
			[op, ln, left, right] = o
			return "(" + luize(left) + " " + (
				"and-op-expr": "and"
				"or-op-expr": "or"
				"eq-op-expr": "=="
				"neq-op-expr": "~="
				"eqs-op-expr": "=="
				"neqs-op-expr": "~="
				"sub-op-expr": "-"
				"mul-op-expr": "*"
				"div-op-expr": "/"
				"mod-op-expr": "%"
				"lt-op-expr": "<"
				"lte-op-expr": "<="
				"gt-op-expr": ">"
				"gte-op-expr": ">=")[op] + " " + luize(right) + ")"

		when "num-op-expr"
			[op, ln, left, right] = o
			return "(#{luize(left)}+0)"

		when "add-op-expr"
			[op, ln, left, right] = o
			return "_JS.add(#{luize(left)}, #{luize(right)})"

		when "lsh-op-expr", "bit-or-op-expr"
			[op, ln, left, right] = o
			return "bit." + (
				"lsh-op-expr": "lshift"
				"bit-or-op-expr": "bor")[op] + "(#{luize(left)}, #{luize(right)})"

		when "neg-op-expr"
			[op, ln, expr] = o
			return (
				"neg-op-expr": "-")[op] + luize(expr)

		# expressions

		when "seq-expr"
			[_, ln, pre, expr] = o
			return "({#{luize(pre)}, #{luize(expr)}})[2]"
		when "this-expr"
			[_, ln] = o
			return "this"
		when "scope-ref-expr"
			[_, ln, value] = o
			return fixRef(value)
		when "static-ref-expr"
			[_, ln, base, value] = o
			if not isSafe(value)
				return luize(["dyn-ref-expr", ln, base, ["str-literal", ln, value]])
			return "(#{luize(base)}).#{value}"
		when "dyn-ref-expr"
			[_, ln, base, expr] = o
			return "(#{luize(base)})[#{luize(expr)}]"
		when "static-method-call-expr"
			[_, ln, base, value, args] = o
			return "#{luize(base)}:#{value}(" + (luize(x) for x in args).join(', ') + ")"
		when "dyn-method-call-expr"
			[_, ln, base, index, args] = o
			return "(function () local _b = #{luize(base)}; return _b[#{luize(index)}](" + ["_b"].concat(luize(x) for x in args).join(', ') + "); end)()"
		when "scope-delete-expr"
			[_, ln, value] = o
			return luize(["scope-assign-expr", ln, value, ["undef-literal", ln]])
		when "static-delete-expr"
			[_, ln, base, value]
			if not isSafe(value)
				return luize(["dyn-delete-expr", ln, base, ["str-literal", ln, value]])
			return luize(["static-assign-expr", ln, base, value, ["undef-literal", ln]])
		when "dyn-delete-expr"
			[_, ln, base, index] = o
			return luize(["dyn-assign-expr", ln, base, index, ["undef-literal", ln]])
		when "new-expr"
			[_, ln, constructor, args] = o
			return "_JS.new(" + [luize(constructor)].concat(luize(x) for x in args).join(', ') + ")"
		when "call-expr"
			[_, ln, expr, args] = o
			return "(" + luize(expr) + ")(" +
				["this"].concat(luize(x) for x in args).join(', ') + ")"
		when "scope-assign-expr"
			[_, ln, value, expr] = o
			return "(function () local _r = #{luize(expr)}; #{fixRef(value)} = _r; return _r end)()"
		when "static-assign-expr"
			[_, ln, base, value, expr] = o
			if not isSafe(value)
				return luize(["dyn-assign-expr", ln, base, ["str-literal", ln, value]])
			return "(function () local _r = #{luize(expr)}; #{luize(base)}.#{value} = _r; return _r end)()"
		when "dyn-assign-expr"
			[_, ln, base, index, expr] = o
			return "(function () local _r = #{luize(expr)}; #{luize(base)}[#{luize(index)}] = _r; return _r end)()"
		when "typeof-expr"
			[_, ln, expr] = o
			return "_JS.typeof(#{luize(expr)})"
		when "void-expr"
			[_, ln, expr] = o
			return "_JS.void(#{luize(expr)})"
		when "if-expr"
			[_, ln, expr, then_expr, else_expr] = o
			return "(#{luize(expr)} and {#{luize(then_expr)}} or {#{luize(else_expr)}})[1]"

		# statements

		when "block-stat"
			[_, ln, stats] = o
			return (luize(x) for x in stats).join('\n')
		when "expr-stat"
			[_, ln, expr] = o
			
			switch expr[0]
				when "scope-assign-expr" 
					[_, ln, value, expr] = expr
					return "#{value} = #{luize(expr)};"
				when "static-assign-expr" 
					[_, ln, base, value, expr] = expr
					return "#{luize(base)}.#{value} = #{luize(expr)};"
				when "dyn-assign-expr" 
					[_, ln, base, index, expr] = expr
					return "#{luize(base)}[#{luize(index)}] = #{luize(expr)};"
				when "call-expr", "static-method-call-expr"
					return "#{luize(expr)};"
				when "seq-expr"
					[_, ln, pre, expr] = o
					return luize(["expr-stat", ln, pre]) + "\n" + luize(["expr-stat", ln, expr])
			return "_JS.void(" + luize(expr) + ");"
		when "ret-stat"
			[_, ln, expr] = o
			return "return" + (if expr then " " + luize(expr) else "") + ";"
		when "if-stat"
			[_, ln, expr, then_stat, else_stat] = o
			return "if #{luize(expr)} then\n#{luize(then_stat)}\n" +
				(if else_stat then "else\n#{luize(else_stat)}\n" else "") + "end"
		when "while-stat"
			[_, ln, expr, stat] = o
			inner = usesContinue(stat)
			loops.push(["while", null, inner])
			name = ""
			ret = "while #{luize(expr)} do\n" +
				(if inner then "local _c#{name} = true; repeat\n" else "") +
				"#{luize(stat)}\n" +
				(if inner then "until true;\nif not _c#{name} then break end\n" else "") +
				"end"
			loops.pop()
			return ret
		when "do-while-stat"
			[_, ln, expr, stat] = o
			inner = usesContinue(stat)
			loops.push(["do", null, inner])
			name = ""
			ret = "repeat\n" +
				(if inner then "local _c#{name} = true; repeat\n" else "") +
				"#{luize(stat)}\n" +
				(if inner then "until true;\nif not _c#{name} then break end\n" else "") +
				"until not (#{luize(expr)});"
			loops.pop()
			return ret
		when "for-stat"
			[_, ln, init, cond, step, body] = o
			cond = ["boolean-literal", ln, true] unless cond
			inner = usesContinue(stat)
			loops.push(["for", null, inner])
			name = ""
			ret = (if init[0] == "var-stat" then luize(init) else luize(["expr-stat", ln, init])) + "\n" +
				"while " + luize(cond) + " do\n" +
				(if inner then "local _c#{name} = true; repeat\n" else "") +
				luize(body) + "\n" +
				(if inner then "until true;\n" else "") +
				(if step then luize(["expr-stat", step[1], step]) + "\n" else "") +
				(if inner then "if not _c#{name} then break end\n" else "") + 
				"end"
			loops.pop()
			return ret
		when "for-in-stat"
			[_, ln, isvar, value, expr, stat] = o
			return (if isvar then "local #{value};\n" else "") +
				"for #{value},_v in pairs(#{luize(expr)}) do\n#{luize(stat)}\nend"
		when "switch-stat"
			[_, ln, expr, cases] = o
			loops.push(["switch", null, false])-1
			ret = "repeat\n" +
				(luize(["var-stat", ln, ["_#{i}", v] for i, [v, _] of cases])) + "\n" +
				(luize(["var-stat", ln, [["_r", expr]]])) + "\n" +
				(for i, [_, stats] of cases
					if _?
						"if _r == _#{i} then\n" + (luize(x) for x in stats).concat(if cases[Number(i)+1] and (not stats.length or stats[-1..][0][0] != "break-stat") then ["_r = _#{Number(i)+1};"] else []).join("\n") + "\nend"
					else
						luize(x) for x in stats
				).join("\n") + "\n" +
				"until true"
			loops.pop()
			return ret
		when "throw-stat"
			[_, ln, expr] = o
			return "error(#{luize(expr)});"
		when "try-stat"
			[_, ln, stats, catch_block, finally_stats] = o
			l = loops.push(["try", null])-1
			ret = """
local _cont, _break, _e = {}, {}, nil
local _s, _r = xpcall(function ()
        #{(luize(x) for x in stats).join('\n')}
		#{if stats[-1..][0][0] != 'ret-stat' then "return _cont" else ""}
    end, function (err)
        _e = err
    end)
if _s == false then
    #{if catch_block then "local " + catch_block[0] + " = _e;\n" +
      (luize(x) for x in catch_block[1]).join('\n') else ""}
end
#{if finally_stats then (luize(x) for x in finally_stats).join('\n') else ""}
if _r == _break then
#{if loops[-2..-1][0]?[1] == "try" then "return _break;" else "break" }
end
if _r ~= _cont then
        return _r
end"""
			loops.pop()
			return ret
		when "var-stat"
			[_, ln, bindings] = o
			return "local " + (k for [k, v] in bindings).join(', ') +
				" = " + ((if v then luize(v) else "nil") for [k, v] in bindings).join(', ') + ";"
		when "defn-stat"
			[_, ln, closure] = o
			return "local #{fixRef(closure[2])}; #{fixRef(closure[2])} = (" + luize(closure) + ");\n"
		when "break-stat"
			#TODO labels
			[_, ln, label] = o
			l = loops.length-1; l-- while loops[l]?[0] == "try"
			return "_c#{l} = false; " + (if loops[-1..][0][0] == "try" then "return _break;" else "break;")
		when "continue-stat"
			#TODO labels
			[_, ln, label] = o
			return (if loops[-1..][0][0] == "try" then "return _break;" else "break;")

		# fallback

		else
			console.log("[ERROR] Undefined compile: " + o[0])
			return "####{o[0]}###"


##########################
###########################
###########################
console.log(arguments.length)

code = fs.readFileSync('./bin/test.js', 'utf-8')


console.log("require('colony-js');\n\n" + colonize(parser.parse(code)))
