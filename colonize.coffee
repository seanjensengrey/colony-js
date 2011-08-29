parser = require('./parser')
ast = require('./ast')
fs = require('fs')

# detects if "continue" is used to address the current loop, named or otherwise

usesLocalContinue = (stat) ->
	continueWalker = (o) ->
		switch o?[0]
			when "while-stat", "do-while-stat", "for-stat", "for-in-stat", "label-stat", "closure-context"
				return []
			when "continue-stat"
				return [true]
			else
				return ast.walk(o, continueWalker)
	return continueWalker(stat).length > 0

usesLabeledContinue = (stat, label) ->
	continueWalker = (o) ->
		switch o?[0]
			when "closure-context"
				return []
			when "label-stat"
				return if o[2] == label then [] else ast.walk(o, continueWalker)
			when "continue-stat"
				return if o[2] == label then [true] else []
			else
				return ast.walk(o, continueWalker)
	return continueWalker(stat).length > 0

usesContinue = (stat, label) ->
	return usesLocalContinue(stat) or (label and usesLabeledContinue(stat, label))

fixRef = (str) ->
	return str.replace(/_/g, '__').replace(/\$/g, '_S')

isSafe = (str) ->
	return str.indexOf("_") != -1

truthy = (cond) ->
	if cond?[0] in ["not-op-expr", "lt-op-expr", "lte-op-expr", "gt-op-expr", "gte-op-expr", "eq-op-expr", "eqs-op-expr", "neq-op-expr", "neqs-op-expr", "instanceof-op-expr", "in-op-expr"]
		return colonize(cond)
	else
		return "_truthy(#{colonize(cond)})"

#
# colonize function
# 

labels = []
loops = []

colonize = (o) ->
	return "" if not o

	# in order of ast.coffee
	switch o[0]

		# contexts

		when "script-context"
			[_, ln, stats] = o
			return (colonize(stat) for stat in stats).join('\n')
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
				ret = "_func(function (this, ...)\n" + namestr +
					"local arguments = _arr((function (...) return arg; end)(...));\n" +
					(if args.length
						"local #{args.join(', ')} = ...;\n"
					else "") +
					(colonize(x) for x in stats).join('\n') + "\n" +
					"end)"
			else
				ret = "_func(function (#{['this'].concat(args).join(', ')})\n" + namestr +
					(colonize(x) for x in stats).join('\n') + "\n" +
					"end)"
			loops = loopsbkp
			return ret

		# literals

		when "num-literal"
			[_, ln, value] = o
			return JSON.stringify(value)
		when "str-literal"
			[_, ln, value] = o
			return "(#{JSON.stringify(value)})"
		when "obj-literal"
			[_, ln, props] = o
			values = ("[\"#{k.replace('\"', '\\\"')}\"]=#{colonize(v)}" for [k, v] in props)
			return "_object({#{values.join(', ')}})"
		when "array-literal"
			[_, ln, exprs] = o
			return "_arr({})" unless exprs.length
			return "_arr({[0]=" + [colonize(exprs[0])].concat(colonize(x) for x in exprs.slice(1)).join(', ') + "})"
		when "undef-literal"
			return "nil"
		when "null-literal"
			return "_null"
		when "boolean-literal"
			[_, ln, value] = o
			return if value then "true" else "false"
			return value
		when "func-literal"
			[_, ln, closure] = o
			return "(" + colonize(closure) + ")"
		#when "regexp-literal"
		#	[_, ln, expr, flags] = o

		# operations

		when "and-op-expr", "or-op-expr", "eq-op-expr", "neq-op-expr", "eqs-op-expr", "neqs-op-expr", "sub-op-expr", "mul-op-expr", "div-op-expr", "mod-op-expr", "lt-op-expr", "lte-op-expr", "gt-op-expr", "gte-op-expr"
			[op, ln, left, right] = o
			return "(" + colonize(left) + " " + (
				#TODO and and or need explicit functions cause they're boolean ish 
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
				"gte-op-expr": ">=")[op] + " " + colonize(right) + ")"

		when "num-op-expr"
			[op, ln, left, right] = o
			return "(#{colonize(left)}+0)"

		when "add-op-expr"
			[op, ln, left, right] = o
			return "_add(#{colonize(left)}, #{colonize(right)})"

		when "lsh-op-expr", "bit-or-op-expr"
			[op, ln, left, right] = o
			return "bit." + (
				"lsh-op-expr": "lshift"
				"bit-or-op-expr": "bor")[op] + "(#{colonize(left)}, #{colonize(right)})"

		when "neg-op-expr"
			[op, ln, expr] = o
			return (
				"neg-op-expr": "-")[op] + colonize(expr)

		# expressions

		when "seq-expr"
			[_, ln, pre, expr] = o
			return "({#{colonize(pre)}, #{colonize(expr)}})[2]"
		when "this-expr"
			[_, ln] = o
			return "this"
		when "scope-ref-expr"
			[_, ln, value] = o
			return fixRef(value)
		when "static-ref-expr"
			[_, ln, base, value] = o
			if not isSafe(value)
				return colonize(["dyn-ref-expr", ln, base, ["str-literal", ln, value]])
			return "(#{colonize(base)}).#{value}"
		when "dyn-ref-expr"
			[_, ln, base, expr] = o
			return "(#{colonize(base)})[#{colonize(expr)}]"
		when "static-method-call-expr"
			[_, ln, base, value, args] = o
			return "#{colonize(base)}:#{value}(" + (colonize(x) for x in args).join(', ') + ")"
		when "dyn-method-call-expr"
			[_, ln, base, index, args] = o
			return "(function () local _b = #{colonize(base)}; return _b[#{colonize(index)}](" + ["_b"].concat(colonize(x) for x in args).join(', ') + "); end)()"
		when "scope-delete-expr"
			[_, ln, value] = o
			return colonize(["scope-assign-expr", ln, value, ["undef-literal", ln]])
		when "static-delete-expr"
			[_, ln, base, value]
			if not isSafe(value)
				return colonize(["dyn-delete-expr", ln, base, ["str-literal", ln, value]])
			return colonize(["static-assign-expr", ln, base, value, ["undef-literal", ln]])
		when "dyn-delete-expr"
			[_, ln, base, index] = o
			return colonize(["dyn-assign-expr", ln, base, index, ["undef-literal", ln]])
		when "new-expr"
			[_, ln, constructor, args] = o
			return "_new(" + [colonize(constructor)].concat(colonize(x) for x in args).join(', ') + ")"
		when "call-expr"
			[_, ln, expr, args] = o
			return "(" + colonize(expr) + ")(" +
				["this"].concat(colonize(x) for x in args).join(', ') + ")"
		when "scope-assign-expr"
			[_, ln, value, expr] = o
			return "(function () local _r = #{colonize(expr)}; #{fixRef(value)} = _r; return _r end)()"
		when "static-assign-expr"
			[_, ln, base, value, expr] = o
			if not isSafe(value)
				return colonize(["dyn-assign-expr", ln, base, ["str-literal", ln, value]])
			return "(function () local _r = #{colonize(expr)}; #{colonize(base)}.#{value} = _r; return _r end)()"
		when "dyn-assign-expr"
			[_, ln, base, index, expr] = o
			return "(function () local _r = #{colonize(expr)}; #{colonize(base)}[#{colonize(index)}] = _r; return _r end)()"
		when "typeof-expr"
			[_, ln, expr] = o
			return "_typeof(#{colonize(expr)})"
		when "void-expr"
			[_, ln, expr] = o
			return "_void(#{colonize(expr)})"
		when "if-expr"
			[_, ln, expr, then_expr, else_expr] = o
			return "(#{colonize(expr)} and {#{colonize(then_expr)}} or {#{colonize(else_expr)}})[1]"
		when "scope-inc-expr"
			[_, ln, pre, inc, value] = o
			value = fixRef(value)
			return "(function () " +
				(if pre then "local _r = #{value}; #{value} = #{value} + #{inc}; return _r"
				else "#{value} = #{value} + #{inc}; return #{value}") +
				" end)()"
		when "static-inc-expr"
			[_, ln, pre, inc, base, value] = o
			return "(function () " +
				(if pre then "local _b, _r = #{colonize(base)}, _b.#{value}; _b.#{value} = _r + #{inc}; return _r"
				else "local _b = #{colonize(base)}; _b.#{value} = _b.#{value} + #{inc}; return _b.#{value}") +
				" end)()"
		when "dyn-inc-expr"
			[_, ln, pre, inc, base, index] = o
			return "(function () " +
				(if pre then "local _b, _i, _r = #{colonize(base)}, #{colonize(index)}, _b[_i]; _b[_i] = _r + #{inc}; return _r"
				else "local _b, _i = #{colonize(base)}, #{colonize(index)}; _b[_i] = _b[_i] + #{inc}; return _b[_i]") +
				" end)()"

		# statements

		when "block-stat"
			[_, ln, stats] = o
			return (colonize(x) for x in stats).join('\n')
		when "expr-stat"
			[_, ln, expr] = o

			switch expr[0]
				when "scope-inc-expr"
					[_, ln, pre, inc, value] = expr
					value = fixRef(value)
					return "#{value} = #{value} + #{inc};"
				when "static-inc-expr"
					[_, ln, pre, inc, base, value] = expr
					return "local _b = #{colonize(base)}; _b.#{value} = _b.#{value} + #{inc};"
				when "dyn-inc-expr"
					[_, ln, pre, inc, base, index] = expr
					return "local _b, _i = #{colonize(base)}, #{index}; _b[_i] = _b[_i] + #{inc};"
				when "pre-dec-op-expr", "post-dec-op-expr"
					[_, ln, expr] = expr
				when "scope-assign-expr" 
					[_, ln, value, expr] = expr
					return "#{value} = #{colonize(expr)};"
				when "static-assign-expr" 
					[_, ln, base, value, expr] = expr
					return "#{colonize(base)}.#{value} = #{colonize(expr)};"
				when "dyn-assign-expr" 
					[_, ln, base, index, expr] = expr
					return "#{colonize(base)}[#{colonize(index)}] = #{colonize(expr)};"
				when "call-expr", "static-method-call-expr"
					return "#{colonize(expr)};"
				when "seq-expr"
					[_, ln, pre, expr] = expr
					return colonize(["expr-stat", ln, pre]) + "\n" + colonize(["expr-stat", ln, expr])
			return "_void(" + colonize(expr) + ");"
		when "ret-stat"
			[_, ln, expr] = o
			return "return" + (if expr then " " + colonize(expr) else "") + ";"
		when "if-stat"
			[_, ln, expr, then_stat, else_stat] = o
			return "if _truthy(#{colonize(expr)}) then\n#{colonize(then_stat)}\n" +
				(if else_stat then "else\n#{colonize(else_stat)}\n" else "") + "end"

		# loops

		when "while-stat"
			[_, ln, expr, stat] = o
			ascend = (x[1] for x in loops when x[0] != 'try' and x[1])
			name = labels.pop() or ""
			cont = usesContinue(stat, name)
			loops.push(["while", name, cont])
			ret = "while #{truthy(expr)} do\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				"#{colonize(stat)}\n" +
				(if cont then "until true;\nif _c#{name} == _break #{[''].concat(ascend).join(' or _c')} then break end\n" else "") +
				"end\n" +
				(if ascend.length then "if _c#{ascend.join(' or _c')} then break end\n" else '')
			loops.pop()
			return ret
		when "do-while-stat"
			[_, ln, expr, stat] = o
			ascend = [""].concat(x[1] for x in loops when x[0] != 'try' and x[1]).join(' or ')
			name = labels.pop() or ""
			cont = usesContinue(stat, name)
			loops.push(["do", name, cont])
			ret = "repeat\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				"#{colonize(stat)}\n" +
				(if cont then "until true;\nif _c#{name} == _break #{ascend} then break end\n" else "") +
				"until not #{truthy(expr)};"
			loops.pop()
			return ret
		when "for-stat"
			[_, ln, init, cond, step, body] = o
			cond = ["boolean-literal", ln, true] unless cond
			ascend = [""].concat(x[1] for x in loops when x[0] != 'try' and x[1]).join(' or ')
			name = labels.pop() or ""
			cont = usesContinue(body, name)
			loops.push(["for", name, cont])
			ret = (if init then (if init[0] == "var-stat" then colonize(init) else colonize(["expr-stat", ln, init]) + "\n") else "") +
				"while #{truthy(cond)} do\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				colonize(body) + "\n" +
				(if cont then "until true;\n" else "") +
				(if step then colonize(["expr-stat", step[1], step]) + "\n" else "") +
				# _cname = _break OR ANYTHING ABOVE IT ~= nil then...
				(if cont then "if _c#{name} == _break #{ascend} then break end\n" else "") + 
				"end"
			loops.pop()
			return ret
		when "for-in-stat"
			[_, ln, isvar, value, expr, stat] = o
			return (if isvar then "local #{value};\n" else "") +
				"for #{value},_v in pairs(#{colonize(expr)}) do\n#{colonize(stat)}\nend"
		when "switch-stat"
			[_, ln, expr, cases] = o
			name = labels.pop() or ""
			loops.push(["switch", name, false])
			ret = "repeat\n" +
				(colonize(["var-stat", ln, ["_#{i}", v] for i, [v, _] of cases])) + "\n" +
				(colonize(["var-stat", ln, [["_r", expr]]])) + "\n" +
				(for i, [_, stats] of cases
					if _?
						"if _r == _#{i} then\n" + (colonize(x) for x in stats).concat(if cases[Number(i)+1] and (not stats.length or stats[-1..][0][0] != "break-stat") then ["_r = _#{Number(i)+1};"] else []).join("\n") + "\nend"
					else
						colonize(x) for x in stats
				).join("\n") + "\n" +
				"until true"
			loops.pop()
			return ret

		when "throw-stat"
			[_, ln, expr] = o
			return "error(#{colonize(expr)});"
		when "try-stat"
			[_, ln, stats, catch_block, finally_stats] = o
			l = loops.push(["try", null])-1
			ret = """
local _cont, _break, _e = {}, {}, nil
local _s, _r = xpcall(function ()
        #{(colonize(x) for x in stats).join('\n')}
		#{if stats[-1..][0][0] != 'ret-stat' then "return _cont" else ""}
    end, function (err)
        _e = err
    end)
if _s == false then
    #{if catch_block then "local " + catch_block[0] + " = _e;\n" +
      (colonize(x) for x in catch_block[1]).join('\n') else ""}
#{if finally_stats then (colonize(x) for x in finally_stats).join('\n') else ""}
elseif _r == _break then
#{if loops[-2..-1][0]?[1] == "try" then "return _break;" else "break" }
elseif _r ~= _cont then
        return _r
end"""
			loops.pop()
			return ret
		when "var-stat"
			[_, ln, bindings] = o
			return ("local #{fixRef(k)} = #{if v then colonize(v) else 'nil'};" for [k, v] in bindings).join(' ') + '\n'
		when "defn-stat"
			[_, ln, closure] = o
			return "local #{fixRef(closure[2])}; #{fixRef(closure[2])} = (" + colonize(closure) + ");\n"
		when "label-stat"
			[_, ln, name, stat] = o
			labels.push(name)
			#TODO change stat to do { } while(false) unless of certain type;
			# this makes this labels array work
			ret = "#{colonize(stat)}"
			labels.pop()
			return ret
		when "break-stat"
			[_, ln, label] = o
			label = label or (x for x in loops when loops[0] != 'try')[-1..][0]?[1] or ""
			return "_c#{label} = _break; " +
				(if loops[-1..][0][0] == "try" then "return _break;" else "break;")
		when "continue-stat"
			#TODO _c down the stack is false until the main one
			[_, ln, label] = o
			label = label or (x for x in loops when loops[0] != 'try')[-1..][0]?[1] or ""
			return "_c#{label} = _cont; " +
				(if loops[-1..][0][0] == "try" then "return _break;" else "break;")

		# fallback

		else
			console.log("[ERROR] Undefined compile: " + o[0])
			return "####{o[0]}###"


##########################
###########################
###########################

code = fs.readFileSync(process.argv[2...][0], 'utf-8')

console.log("require('../res/colony-js');\n\n" + colonize(parser.parse(code)))
