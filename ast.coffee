###

AST Structure

Contexts:

	script-context (type context): stats
	closure-context (type context): name args stats

Literals:

	num-literal (type literal): value
	str-literal (type literal): value
	obj-literal (type literal): props
	array-literal (type literal): exprs
	undef-literal (type literal): 
	null-literal (type literal): 
	boolean-literal (type literal): value
	func-literal (type literal): closure
	regexp-literal (type literal): expr flags

Operations:

	num-op-expr (type unary-op-expr): expr
	neg-op-expr (type unary-op-expr): expr
	not-op-expr (type unary-op-expr): expr
	bit-not-op-expr (type unary-op-expr): expr

	lt-op-expr (type binary-op-expr): left right
	lte-op-expr (type binary-op-expr): left right
	gt-op-expr (type binary-op-expr): left right
	gte-op-expr (type binary-op-expr): left right
	add-op-expr (type binary-op-expr): left right
	sub-op-expr (type binary-op-expr): left right
	mul-op-expr (type binary-op-expr): left right
	div-op-expr (type binary-op-expr): left right
	mod-op-expr (type binary-op-expr): left right
	or-op-expr (type binary-op-expr): left right
	and-op-expr (type binary-op-expr): left right
	lsh-op-expr (type binary-op-expr): left right
	rsh-op-expr (type binary-op-expr): left right
	bit-and-op-expr (type binary-op-expr): left right
	bit-or-op-expr (type binary-op-expr): left right
	bit-xor-op-expr (type binary-op-expr): left right
	eq-op-expr (type binary-op-expr): left right
	eqs-op-expr (type binary-op-expr): left right
	neq-op-expr (type binary-op-expr): left right
	neqs-op-expr (type binary-op-expr): left right
	instanceof-op-expr (type binary-op-expr): left right
	in-op-expr (type binary-op-expr): left right

Expressions:

	seq-expr (type expr): pre expr
	this-expr (type expr): 
	scope-ref-expr (type expr): value
	static-ref-expr (type expr): base value
	dyn-ref-expr (type expr): base index
	static-method-call-expr (type expr): base value args
	dyn-method-call-expr (type expr): base index args
	scope-delete-expr (type expr): value
	static-delete-expr (type expr): base value
	dyn-delete-expr (type expr): base index
	new-expr (type expr): constructor args
	call-expr (type expr): expr args
	scope-assign-expr (type expr): value expr
	static-assign-expr (type expr): base value expr
	dyn-assign-expr (type expr): base index expr
	typeof-expr (type expr): expr
	void-expr (type expr): expr
	if-expr (type expr): expr then-expr else-exp
	scope-inc-expr (type expr): pre inc value
	static-inc-expr (type expr): pre inc base value
	dyn-inc-expr (type expr): pre inc base index

Statements:

	block-stat (type stat): stats
	expr-stat (type stat): expr
	ret-stat (type stat): expr
	if-stat (type stat): expr then-stat else-stat
	while-stat (type stat): expr stat
	do-while-stat (type stat): expr stat
	for-stat (type stat): init expr step stat
	for-in-stat (type stat): isvar value expr stat
	switch-stat (type stat): expr cases
	throw-stat (type stat): expr
	try-stat (type stat): stats catch-block finally-stats
	var-stat (type stat): vars 
	defn-stat (type stat): closure
	label-stat (type stat): name, stat
	break-stat (type stat): label
	continue-stat (type stat): label

###

ast = exports

class ast.Node
	serialize: ->
		return [@name, (@[k] for k in ast.types[@name])...]

ast.types = {}
ast.define = (name, args) ->
	ast.types[name] = args

ast.parse = (o) ->
		

#
# contexts
#

ast.isContext = (o) -> o?[0].match(/-context$/)

ast.define "script-context", ["stats"]
ast.define "closure-context", ["name", "args", "stats"]

#
# literals
#

ast.isLiteral = (o) -> o?[0].match(/-literal$/)

#
# operations
#

ast.isOp = (o) -> o?[0].match(/-op-expr$/)
ast.isUnaryOp = (o) -> ast.isOp(o) and o.length == 3
ast.isBinaryOp = (o) -> ast.isOp(o) and o.length == 4

#
# expressions
#

ast.isExpr = (o) -> o?[0].match(/-expr$/)

#
# statements
#

ast.isStat = (o) -> o?[0].match(/-stat$/)

ast.define "block-stat", ["stats"]
ast.define "expr-stat", ["expr"]
ast.define "ret-stat", ["expr"]
ast.define "if-stat", ["expr", "thenStat", "elseStat"]
ast.define "while-stat", ["expr", "stat"]
ast.define "do-while-stat", ["expr", "stat"]
ast.define "for-stat", ["init", "expr", "step", "stat"]
ast.define "for-in-stat", ["isvar", "value", "expr", "stat"]
ast.define "switch-stat", ["expr", "cases"]
ast.define "throw-stat", ["expr"]
ast.define "try-stat", ["stats", "catchBlock", "finallyStats"]
ast.define "var-stat", ["vars"]
ast.define "defn-stat", ["closure"]
ast.define "label-stat", ["name", "stat"]
ast.define "break-stat", ["label"]
ast.define "continue-stat", ["label"]

#
# walker
#

ast.walk = (o, f = ast.walk) ->
	# operations

	if ast.isUnaryOp(o)
		[_, ln, expr] = o
		return f(expr)
	if ast.isBinaryOp(o)
		[_, ln, left, right] = o
		return f(left).concat(f(right))

	switch o?[0]

		# contexts

		when "script-context"
			[_, ln, stats] = o
			return f(x) for x in stats
		when "closure-context"
			[_, ln, name, args, stats] = o
			return f(x) for x in stats

		# literals

		when "null-literal"
			[_, ln] = o
			return []
		when "boolean-literal"
			[_, ln, value] = o
			return []
		when "num-literal"
			[_, ln, value] = o
			return []
		when "undef-literal"
			[_, ln, value] = o
			return []
		when "str-literal"
			[_, ln, value] = o
			return []
		when "regexp-literal"
			[_, ln, expr, flags] = o
			return []
		when "array-literal"
			[_, ln, exprs] = o
			return f(x) for x in exprs
		when "obj-literal"
			[_, ln, props] = o
			return f(v) for [k, v] in props
		when "func-literal"
			[_, ln, closure] = o
			return f(closure)

		# expressions

		when "scope-ref-expr"
			[_, ln, value] = o
			return []
		when "static-ref-expr"
			[_, ln, base, value] = o
			return f(base)
		when "dyn-ref-expr"
			[_, ln, base, index] = o
			return f(base).concat(f(index))
		when "static-method-call-expr"
			[_, ln, base, value, args] = o
			return f(base).concat((f(x) for x in args)...)
		when "call-expr"
			[_, ln, expr, args] = o
			return f(expr).concat((f(x) for x in args)...)
		when "new-expr"
			[_, ln, constructor, args] = o
			return f(constructor).concat((f(x) for x in args)...)
		when "scope-assign-expr"
			[_, ln, value, expr] = o
			return f(expr)
		when "static-assign-expr"
			[_, ln, base, value, expr] = o
			return f(base).concat(f(expr))
		when "dyn-assign-expr"
			[_, ln, base, index, expr] = o
			return f(base).concat(f(index), f(expr))
		when "scope-delete-expr"
			[_, ln, value] = o
			return []
		when "static-delete-expr"
			[_, ln, base, value] = o
			return f(base)
		when "dyn-delete-expr"
			[_, ln, base, index] = o
			return f(base).concat(f(index))
		when "typeof-expr"
			[_, ln, expr] = o
			return f(expr)
		when "void-expr"
			[_, ln, expr] = o
			return f(expr)
		when "this-expr"
			[_, ln] = o
			return []
		when "if-expr"
			[_, ln, expr, then_expr, else_expr] = o
			return f(expr).concat(f(then_expr), f(else_expr))
		when "seq-expr"
			[_, ln, pre, expr] = o
			return f(pre).concat(f(expr))

		# statements

		when "block-stat"
			[_, ln, stats] = o
			return [].concat((f(x) for x in stats)...)
		when "expr-stat"
			[_, ln, expr] = o
			return f(expr)
		when "ret-stat"
			[_, ln, expr] = o
			return if expr then f(expr) else []
		when "throw-stat"
			[_, ln, expr] = o
			return f(expr)
		when "while-stat", "do-while-stat"
			[_, ln, expr, stat] = o
			return f(expr).concat(f(stat))
		when "try-stat"
			[_, ln, stats, catch_block, finally_stats] = o
			return [].concat(
				(f(x) for x in stats)...,
				(if catch_block
					[value, stats] = catch_block
					(f(x) for x in stats)
				else []),
				(f(x) for x in (finally_stats or []))...)
		when "for-stat"
			[_, ln, init, expr, step, stat] = o
			return [].concat(
				(if init then f(init) else []),
				(if expr then f(expr) else []),
				(if step then f(step) else []),
				f(stat))
		when "if-stat"
			[_, ln, expr, then_stat, else_stat] = o
			return [].concat(
				f(expr),
				f(then_stat),
				(if else_stat then f(else_stat) else []))
		when "switch-stat"
			[_, ln, expr, cases] = o
			return f(expr).concat(
				((if expr then f(expr) else []).concat((f(x) for x in stats)...) for [expr, stats] in cases)...)
		when "break-stat"
			[_, ln, label] = o
			return []
		when "continue-stat"
			[_, ln, label] = o
			return []
		when "for-in-stat"
			[_, ln, isvar, value, expr, stat] = o
			return f(expr).concat(f(stat))
		when "var-stat"
			[_, ln, vars] = o
			return [].concat(((if v then f(v) else []) for [k, v] in vars)...)
		when "defn-stat"
			[_, ln, closure] = o
			return f(closure)

		# failsafe

		else
			return []

#
# analysis
#

ast.strings = (o, f = ast.strings) ->
	switch o?[0]
		when "str-literal"
			[_, ln, value] = o
			return [value]
		else
			return ast.walk(o, f)

ast.numbers = (o, f = ast.numbers) ->
	switch o?[0]
		when "num-literal"
			[_, ln, value] = o
			return [value]
		else
			return ast.walk(o, f)

ast.regexps = (o, f = ast.regexps) ->
	switch o?[0]
		when "regexp-literal"
			[_, ln, expr, flags] = o
			return [[expr, flags]]
		else
			return ast.walk(o, f)

ast.contextStats = (ctx) ->
	switch ctx?[0]
		when "script-context"
			return ctx[2]
		when "closure-context"
			return ctx[4]
	return []

ast.contexts = (o, f = ast.contexts) ->
	switch o?[0]
		when "script-context"
			[_, ln, stats] = o
			return [o].concat((f(x) for x in stats)...)
		when "closure-context"
			[_, ln, name, args, stats] = o
			return [o].concat((f(x) for x in stats)...)
		else
			return ast.walk(o, f)

ast.vars = (o, f = ast.vars) ->
	switch o?[0]
		when "closure-context"
			[_, ln, name, args, stats] = o
			return (if name? then [name] else []).concat(args, (f(x) for x in stats)...)
		when "var-stat"
			[_, ln, vars] = o
			return (k for [k, v] in vars).concat((f(v) for [k, v] in vars when v)...)
		when "for-in-stat"
			[_, ln, isvar, value, expr, stat] = o
			return (if isvar then [value] else []).concat(f(stat))
		when "try-stat"
			[_, ln, stats, catch_block, finally_stats] = o
			return (if catch_block
					[label, stats] = catch_block
					[label].concat((f(x) for x in stats)...)
				else []).concat((if finally_stats then f(x) for x in finally_stats else [])...)
		when "scope-ref-expr"
			[_, ln, value] = o
			return if value == "arguments" then ["arguments"] else []
		when "defn-stat", "func-literal"
			[_, ln, [_, ln, name, args, stats]] = o
			return if name? then [name] else []
		else
			return ast.walk(o, f)

ast.localVars = (o, f = ast.localVars) ->
	switch o?[0]
		when "script-context"
			[_, ln, stats] = o
			return []
		when "closure-context"
			[_, ln, name, args, stats] = o
			return []
		else
			return ast.vars(o, f)

ast.usesArguments = (closure) ->
	return "arguments" in [].concat((ast.localVars(x) for x in ast.contextStats(closure))...)

ast.localRefs = (o, f = ast.localRefs) ->
	switch o?[0]
		when "script-context"
			[_, ln, stats] = o
			return []
		when "closure-context"
			[_, ln, name, args, stats] = o
			return []
		when "scope-ref-expr"
			[_, ln, value] = o
			return [value]
		when "scope-assign-expr"
			[_, ln, value, expr] = o
			return [value]
		when "scope-delete-expr"
			[_, ln, value] = o
			return [value]
		else
			return ast.walk(o, f)

set = (a) ->
	o = {}; r = []
	o[k] = true for k in a
	r.push(k) for k, _ of o
	return r

ast.localUndeclaredRefs = (ctx) ->
	stats = ast.contextStats(ctx)
	refs = [].concat((ast.localRefs(x) for x in stats)...)
	vars = [].concat((ast.localVars(x) for x in stats)...)
	return set(k for k in refs when k not in vars)

ast.undeclaredRefs = (o) ->
	return set([].concat((ast.localUndeclaredRefs(ctx) for ctx in ast.contexts(o))...))
