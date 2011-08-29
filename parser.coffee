preparser = require('./parser-base.js')

genAst = (o) ->
	# in order of parser-base
	switch o[0]
		when "atom", "name"
			[_, ln, value] = o
			return switch value
				when "true" then ["boolean-literal", ln, true]
				when "false" then ["boolean-literal", ln, false]
				when "this" then ["this-expr", ln]
				when "null" then ["null-literal", ln]
				when "undefined" then ["undef-literal", ln]
				else ["scope-ref-expr", ln, value]
		when "num"
			[_, ln, value] = o
			return ["num-literal", ln, value]
		when "string"
			[_, ln, value] = o
			return ["str-literal", ln, value]
		when "array"
			[_, ln, elems] = o
			return ["array-literal", ln, genAst(x) for x in elems]
		when "object"
			[_, ln, elems] = o
			return ["obj-literal", ln, [k, genAst(v)] for [k, v] in elems]
		when "regexp"
			[_, ln, expr, flags] = o
			return ["regexp-literal", ln, expr, flags]

		when "assign"
			[_, ln, op, place, val] = o
			val = ["binary", ln, op, place, val] unless op == true
			return switch place[0]
				when "name" then ["scope-assign-expr", ln, place[2], genAst(val)]
				when "dot" then ["static-assign-expr", ln, genAst(place[2]), place[3], genAst(val)]
				when "sub" then ["dyn-assign-expr", ln, genAst(place[2]), genAst(place[3]), genAst(val)]
		when "binary"
			[_, ln, op, lhs, rhs] = o
			return [(
				"+": "add-op-expr"
				"-": "sub-op-expr"
				"*": "mul-op-expr"
				"/": "div-op-expr"
				"%": "mod-op-expr"
				"<": "lt-op-expr"
				">": "gt-op-expr"
				"<=": "lte-op-expr"
				">=": "gte-op-expr"
				"==": "eq-op-expr"
				"===": "eqs-op-expr"
				"!=": "neq-op-expr"
				"!==": "neqs-op-expr"
				"||": "or-op-expr"
				"&&": "and-op-expr"
				"<<": "lsh-op-expr"
				">>": "rsh-op-expr"
				"&": "bit-or-op-expr"
				"|": "bit-or-op-expr"
				"^": "bit-xor-op-expr"
				"instanceof": "instanceof-op-expr"
				"in": "in-op-expr")[op],
					ln, genAst(lhs), genAst(rhs)]
		when "unary-postfix"
			[_, ln, op, place] = o
			inc = if op == "++" then 1 else -1
			switch place[0]
				when "name" then ["scope-inc-expr", ln, false, inc, place[2]]
				when "dot" then ["static-inc-expr", ln, false, inc, genAst(place[2]), place[3]]
				when "sub" then ["dyn-inc-expr", ln, false, inc, genAst(place[2]), genAst(place[3])]
		when "unary-prefix"
			[_, ln, op, place] = o
			return switch op
				when "+" then ["num-op-expr", ln, genAst(place)]
				when "-" then ["neg-op-expr", ln, genAst(place)]
				when "~" then ["bit-op-expr", ln, genAst(place)]
				when "++", "--"
					inc = if op == "++" then 1 else -1
					switch place[0]
						when "name" then ["scope-inc-expr", ln, true, inc, place[2]]
						when "dot" then ["static-inc-expr", ln, true, inc, genAst(place[2]), place[3]]
						when "sub" then ["dyn-inc-expr", ln, true, inc, genAst(place[2]), genAst(place[3])]
				when "!" then ["not-op-expr", ln, genAst(place)]
				when "void" then ["void-expr", ln, genAst(place)]
				when "typeof" then ["typeof-expr", ln, genAst(place)]
				when "delete"
					switch place[0]
						when "name" then ["scope-delete-expr", ln, place[2]]
						when "dot" then ["static-delete-expr", ln, genAst(place[2]), place[3]]
						when "sub" then ["dyn-delete-expr", ln, genAst(place[2]), genAst(place[3])]
		when "call"
			[_, ln, func, args] = o
			switch func[0]
				when "dot"
					[_, ln, base, value] = func
					return ["static-method-call-expr", ln, genAst(base), value, genAst(x) for x in args]
				else
					return ["call-expr", ln, genAst(func), genAst(x) for x in args]
		when "dot"
			[_, ln, obj, attr] = o
			return ["static-ref-expr", ln, genAst(obj), attr]
		when "sub"
			[_, ln, obj, attr] = o
			return ["dyn-ref-expr", ln, genAst(obj), genAst(attr)]
		when "seq"
			[_, ln, form1, result] = o
			return ["seq-expr", ln, genAst(form1), genAst(result)]
		when "conditional"
			[_, ln, test, thn, els] = o
			return ["if-expr", ln, genAst(test), genAst(thn), genAst(els)]
		when "function"
			[_, ln, name, args, stats] = o
			return ["func-literal", ln, ["closure-context", ln, name, args, genAst(x) for x in stats]]
		when "new"
			[_, ln, func, args] = o
			return ["new-expr", ln, genAst(func), genAst(x) for x in args]

		when "toplevel"
			[_, ln, stats] = o
			return ["script-context", ln, genAst(x) for x in stats]
		when "block"
			[_, ln, stats] = o
			return ["block-stat", ln, genAst(x) for x in stats]
		when "stat"
			[_, ln, form] = o
			return ["expr-stat", ln, genAst(form)]
		when "label"
			[_, ln, name, form] = o
			return ["label-stat", ln, name, genAst(form)]
		when "if"
			[_, ln, test, thn, els] = o
			return ["if-stat", ln, genAst(test), genAst(thn), if els then genAst(els) else null]
		#when "with"
		#	[_, ln, obj, body] = o
		when "var"
			[_, ln, bindings] = o
			return ["var-stat", ln, [k, if v then genAst(v) else null] for [k, v] in bindings]
		when "defun"
			[_, ln, name, args, stats] = o
			return ["defn-stat", ln, ["closure-context", ln, name, args, genAst(x) for x in stats]]
		when "return"
			[_, ln, value] = o
			return ["ret-stat", ln, if value then genAst(value) else null]
		#when "debugger"
		#	[_, ln] = o
		when "try"
			[_, ln, body, ctch, fnlly] = o
			return ["try-stat", ln, genAst(x) for x in body,
				(if ctch
					[label, stats] = ctch
					[label, genAst(x) for x in stats]),
				(if fnlly
					genAst(x) for x in fnlly)]
		when "throw"
			[_, ln, expr] = o
			return ["throw-stat", ln, genAst(expr)]
		when "break"
			[_, ln, label] = o
			return ["break-stat", ln, label]
		when "continue"
			[_, ln, label] = o
			return ["continue-stat", ln, label]
		when "while"
			[_, ln, cond, body] = o
			return ["while-stat", ln, genAst(cond), genAst(body)]
		when "do"
			[_, ln, cond, body] = o
			return ["do-while-stat", ln, genAst(cond), genAst(body)]
		when "for"
			[_, ln, init, cond, step, body] = o
			return ["for-stat", ln,
				if init then genAst(init) else null,
				if cond then genAst(cond) else null,
				if step then genAst(step) else null,
				if body then genAst(body) else []]
		when "for-in"
			[_, ln, vari, name, obj, body] = o
			return ["for-in-stat", ln, vari, name, genAst(obj), genAst(body)]
		when "switch"
			[_, ln, val, body] = o
			return ["switch-stat", ln, genAst(val),
				for [cse, stats] in body
					[(if cse then genAst(cse) else null),
					 genAst(x) for x in stats]]

		else
			console.log("[ERROR] Can't generate AST for node \"#{o[0]}\"")

exports.parse = (str) ->
	try
		ast = preparser.parse(str)
	catch e
		throw new Error("Parsing error: " + e)
	return genAst(ast)
