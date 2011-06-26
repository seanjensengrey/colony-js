parser = require('./parser')
fs = require('fs')

luize = (o) ->
	return "" if not o

	switch o[0]

		# contexts

		when "script-context"
			[_, ln, stats] = o
			return (luize(stat) for stat in stats).join('\n')
		when "closure-context"
			[_, ln, name, args, stats] = o
			#TODO name?
			return "function (#{['this'].concat(args).join(', ')})\n" +
				(luize(x) for x in stats).join('\n') + "\n" +
				"end"

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
			return value
		when "static-ref-expr"
			[_, ln, base, value] = o
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
			return "(function () local _r = #{luize(expr)}; #{value} = _r; return _r end)()"
		when "static-assign-expr"
			[_, ln, base, value, expr] = o
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
			return "while #{luize(expr)} do\n#{luize(stat)}\nend"
		when "do-while-stat"
			[_, ln, expr, stat] = o
			return "repeat\n#{luize(stat)}\nuntil not (#{luize(expr)});"
		when "for-stat"
			[_, ln, init, cond, step, body] = o
			cond = ["boolean-literal", ln, true] unless cond
			return (if init[0] == "var-stat" then luize(init) else luize(["expr-stat", ln, init])) + "\n" +
				"while " + luize(cond) + " do\n" +
				luize(body) + "\n" +
				(if step then luize(["expr-stat", step[1], step]) + "\n" else "") +
				"end"
		when "for-in-stat"
			[_, ln, isvar, value, expr, stat] = o
			return (if isvar then "local #{value};\n" else "") +
				"for #{value},_v in pairs(#{luize(expr)}) do\n#{luize(stat)}\nend"
		when "switch-stat"
			[_, ln, expr, cases] = o
			return "repeat\n" +
				(luize(["var-stat", ln, ["_#{i}", v] for i, [v, _] of cases])) + "\n" +
				(luize(["var-stat", ln, [["_r", expr]]])) + "\n" +
				(for i, [_, stats] of cases
					if _?
						"if _r == _#{i} then\n" + (luize(x) for x in stats).concat(if cases[Number(i)+1] and (not stats.length or stats[-1..][0][0] != "break-stat") then ["_r = _#{Number(i)+1};"] else []).join("\n") + "\nend"
					else
						luize(x) for x in stats
				).join("\n") + "\n" +
				"until true"
		#when "throw"
		#	[_, ln, expr] = o
		#when "try-stat"
		#	[_, ln, stats, catch_block, finally_stats]
		when "var-stat"
			[_, ln, bindings] = o
			return "local " + (k for [k, v] in bindings).join(', ') +
				" = " + ((if v then luize(v) else "nil") for [k, v] in bindings).join(', ') + ";"
		when "defn-stat"
			[_, ln, closure] = o
			return "local #{closure[2]}; #{closure[2]} = (" + luize(closure) + ");\n"
		when "break-stat"
			[_, ln, label] = o
			#TODO labels
			return "break;"
		#when "continue-stat"
		#	[_, ln, label] = o

		# fallback

		else
			console.log("[ERROR] Undefined compile: " + o[0])
			return "####{o[0]}###"


##########################
###########################
###########################

code = fs.readFileSync('./test.js', 'utf-8')

#console.log(luize(exports.parse(code)))
#luize(exports.parse(code))

console.log("require('colony-js');\n\n" + luize(parser.parse(code)))
