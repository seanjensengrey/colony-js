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

	post-inc-op-expr (type unary-op-expr): expr
	pre-inc-op-expr (type unary-op-expr): expr
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
	if-expr (type expr): expr then-expr else-expr

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
	break-stat (type stat): label
	continue-stat (type stat): label

###

ast = exports

ast.isLiteral = (o) -> o?[0].match(/-literal$/)
ast.isOp = (o) -> o?[0].match(/-op-expr$/)
ast.isUnaryOp = (o) -> ast.isOp(o) and o.length == 3
ast.isBinaryOp = (o) -> ast.isOp(o) and o.length == 4
ast.isExpr = (o) -> o?[0].match(/-expr$/)
ast.isStat = (o) -> o?[0].match(/-stat$/)
ast.isContext = (o) -> o?[0].match(/-context$/)

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
# predefined walkers
#

ast.strings = (o) ->
	switch o?[0]
		when "str-literal"
			[_, ln, value] = o
			return [value]
		else
			return ast.walk(o, ast.strings)

ast.numbers = (o) ->
	switch o?[0]
		when "num-literal"
			[_, ln, value] = o
			return [value]
		else
			return ast.walk(o, ast.numbers)

ast.regexps = (o) ->
	switch o?[0]
		when "regexp-literal"
			[_, ln, expr, flags] = o
			return [[expr, flags]]
		else
			return ast.walk(o, ast.regexps)

ast.contexts = (o) ->
	switch o?[0]
		when "script-context"
			[_, ln, stats] = o
			return [o].concat((ast.contexts(x) for x in stats)...)
		when "closure-context"
			[_, ln, name, args, stats] = o
			return [o].concat((ast.contexts(x) for x in stats)...)
		else
			return ast.walk(o, ast.contexts)
