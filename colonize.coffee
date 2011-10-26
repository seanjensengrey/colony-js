jast = require 'jast'
fs = require 'fs'

# detects if "continue" is used to address the current loop, named or otherwise

keywords = ["end"]

usesLocalContinue = (stat) ->
	continueWalker = (n) ->
		switch n.type
			when "while-stat", "do-while-stat", "for-stat", "for-in-stat", "label-stat", "closure-context"
				return []
			when "continue-stat"
				return [true]
			else
				return jast.walk(n, continueWalker)
	return continueWalker(stat).length > 0

usesLabeledContinue = (stat, label) ->
	continueWalker = (n) ->
		switch n.type
			when "closure-context"
				return []
			when "label-stat"
				return if n.name == label then [] else jast.walk(n, continueWalker)
			when "continue-stat"
				return if n.label == label then [true] else []
			else
				return jast.walk(n, continueWalker)
	return continueWalker(stat).length > 0

usesContinue = (stat, label) ->
	return usesLocalContinue(stat) or (label and usesLabeledContinue(stat, label))

fixRef = (str) ->
	if str in keywords
		return '_K_' + str
	return str.replace(/_/g, '__').replace(/\$/g, '_S')

isSafe = (str) ->
	return str not in keywords

truthy = (cond) ->
	if cond.type in ["not-op-expr", "lt-op-expr", "lte-op-expr", "gt-op-expr", "gte-op-expr", "eq-op-expr", "eqs-op-expr", "neq-op-expr", "neqs-op-expr", "instanceof-op-expr", "in-op-expr"]
		return colonize(cond)
	else
		return "_JS._truthy(#{colonize(cond)})"

colonizeContext = (ctx) ->
	# variable declarations
	vars = [].concat((jast.localVars(stat) for stat in ctx.stats)...)
	ret = if vars.length then "local #{(fixRef(x) for x in vars).join(', ')};\n" else ""

	# hoist functions, then statements
	funcs = (stat for stat in ctx.stats when stat.type == 'defn-stat')
	stats = (stat for stat in ctx.stats when stat and not (stat.type == 'defn-stat'))
	ret += (colonize(stat) for stat in funcs.concat(ctx.stats)).join('\n')

	return ret

#
# colonize function
# 

labels = []
loops = []

colonize = (n) ->
	return "" if not n

	switch n.type

		# contexts

		when "script-context"
			return colonizeContext(n)
		when "closure-context"
			{ln, name, args, stats} = n

			# fix references
			name = fixRef(name) if name; args = (fixRef(x) for x in args)

			# assign self-named function reference only when necessary
			namestr = ""
			if name in jast.undefinedRefs(n)
				namestr = "local #{name} = debug.getinfo(1, 'f').func;\n"

			loopsbkp = loops
			loops = []
			if jast.usesArguments(n)
				ret = "_JS._func(function (this, ...)\n" + namestr +
					"local arguments = _JS._arr((function (...) return arg; end)(...));\n" +
					(if args.length
						"local #{args.join(', ')} = ...;\n"
					else "") +
					colonizeContext(n) + "\n" +
					"end)"
			else
				ret = "_JS._func(function (#{['this'].concat(args).join(', ')})\n" + namestr +
					colonizeContext(n) + "\n" +
					"end)"
			loops = loopsbkp
			return ret

		# literals

		when "num-literal"
			{ln, value} = n
			return JSON.stringify(value)
		when "str-literal"
			{ln, value} = n
			return "(#{JSON.stringify(value)})"
		when "obj-literal"
			{ln, props} = n
			values = ("[\"#{value.replace('\"', '\\\"')}\"]=#{colonize(expr)}" for {value, expr} in props)
			return "_JS._obj({#{values.join(', ')}})"
		when "array-literal"
			{ln, exprs} = n
			return "_JS._arr({})" unless exprs.length
			return "_JS._arr({[0]=" + [].concat(colonize(x) for x in exprs).join(', ') + "})"
		when "undef-literal"
			return "nil"
		when "null-literal"
			return "_JS._null"
		when "boolean-literal"
			{ln, value} = n
			return if value then "true" else "false"
			return value
		when "func-literal"
			{ln, closure} = n
			return "(" + colonize(closure) + ")"
		when "regexp-literal"
			{ln, expr, flags} = n
			return "_JS.Regexp(#{JSON.stringify(expr)})"

		# operations

		when "and-op-expr", "or-op-expr", "eq-op-expr", "neq-op-expr", "eqs-op-expr", "neqs-op-expr", "sub-op-expr", "mul-op-expr", "div-op-expr", "mod-op-expr", "lt-op-expr", "lte-op-expr", "gt-op-expr", "gte-op-expr"
			{ln, left, right} = n
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
				"gte-op-expr": ">=")[n.type] + " " + colonize(right) + ")"

		when "num-op-expr"
			{ln, left, right} = n
			return "(#{colonize(left)}+0)"

		when "add-op-expr"
			{ln, left, right} = n
			return "_JS._add(#{colonize(left)}, #{colonize(right)})"

		when "lsh-op-expr", "bit-or-op-expr"
			{ln, left, right} = n
			return "_JS._bit." + (
				"lsh-op-expr": "lshift"
				"bit-or-op-expr": "bor")[n.type] + "(#{colonize(left)}, #{colonize(right)})"

		when "neg-op-expr", "not-op-expr"
			{ln, expr} = n
			return (
				"neg-op-expr": "-"
				"not-op-expr": "not")[n.type] + colonize(expr)

		when "typeof-op-expr"
			{ln, expr} = n
			return "_JS._typeof(#{colonize(expr)})"
		when "void-op-expr"
			{ln, expr} = n
			return "_JS._void(#{colonize(expr)})"

		when "seq-op-expr"
			{ln, left, right} = n
			return "({#{colonize(left)}, #{colonize(right)}})[2]"

		# expressions

		when "this-expr"
			return "this"
		when "scope-ref-expr"
			{ln, value} = n
			return fixRef(value)
		when "static-ref-expr"
			{ln, base, value} = n
			if not isSafe(value)
				return colonize({type: "dyn-ref-expr", ln: ln, base: base, index: {type: "str-literal", ln: ln, value: value}})
			return "(#{colonize(base)}).#{value}"
		when "dyn-ref-expr"
			{ln, base, index} = n
			return "(#{colonize(base)})[#{colonize(index)}]"
		when "static-method-call-expr"
			{ln, base, value, args} = n
			return "#{colonize(base)}:#{value}(" + (colonize(x) for x in args).join(', ') + ")"
		when "dyn-method-call-expr"
			{ln, base, index, args} = n
			return "(function () local _b = #{colonize(base)}; return _b[#{colonize(index)}](" + ["_b"].concat(colonize(x) for x in args).join(', ') + "); end)()"
		when "scope-delete-expr"
			{ln, value} = n
			return colonize({type: "scope-assign-expr", ln: ln, value: value, expr: {type: "undef-literal", ln: ln}})
		when "static-delete-expr"
			{ln, base, value} = n
			if not isSafe(value)
				return colonize({type: "dyn-delete-expr", ln: ln, base: base, index: {type: "str-literal", ln: ln, value: value}})
			return colonize({type: "static-assign-expr", ln: ln, base: base, value: value, expr: {type: "undef-literal", ln: ln}})
		when "dyn-delete-expr"
			{ln, base, index} = n
			return colonize({type: "dyn-assign-expr", ln: ln, base: base, index: index, expr: {type: "undef-literal", ln: ln}})
		when "new-expr"
			{ln, constructor, args} = n
			return "_JS._new(" + [colonize(constructor)].concat(colonize(x) for x in args).join(', ') + ")"
		when "call-expr"
			{ln, expr, args} = n
			return "(" + colonize(expr) + ")(" +
				["this"].concat(colonize(x) for x in args).join(', ') + ")"
		when "scope-assign-expr"
			{ln, value, expr} = n
			return "(function () local _r = #{colonize(expr)}; #{fixRef(value)} = _r; return _r end)()"
		when "static-assign-expr"
			{ln, base, value, expr} = n
			if not isSafe(value)
				return colonize({type: "dyn-assign-expr", ln: ln, base: base, index: {type: "str-literal", ln: ln, value: value}})
			return "(function () local _r = #{colonize(expr)}; #{colonize(base)}.#{value} = _r; return _r end)()"
		when "dyn-assign-expr"
			{ln, base, index, expr} = n
			return "(function () local _r = #{colonize(expr)}; #{colonize(base)}[#{colonize(index)}] = _r; return _r end)()"
		when "instanceof-op-expr"
			{ln, expr} = n
			return "_JS._instanceof(#{colonize(expr)})"
		when "if-expr"
			{ln, expr, thenExpr, elseExpr} = n
			return "(#{colonize(expr)} and {#{colonize(thenExpr)}} or {#{colonize(elseExpr)}})[1]"
		when "scope-inc-expr"
			{ln, pre, inc, value} = n
			value = fixRef(value)
			return "(function () " +
				(if pre then "local _r = #{value}; #{value} = #{value} + #{inc}; return _r"
				else "#{value} = #{value} + #{inc}; return #{value}") +
				" end)()"
		when "static-inc-expr"
			{ln, pre, inc, base, value} = n
			return "(function () " +
				(if pre then "local _b, _r = #{colonize(base)}, _b.#{value}; _b.#{value} = _r + #{inc}; return _r"
				else "local _b = #{colonize(base)}; _b.#{value} = _b.#{value} + #{inc}; return _b.#{value}") +
				" end)()"
		when "dyn-inc-expr"
			{ln, pre, inc, base, index} = n
			return "(function () " +
				(if pre then "local _b, _i, _r = #{colonize(base)}, #{colonize(index)}, _b[_i]; _b[_i] = _r + #{inc}; return _r"
				else "local _b, _i = #{colonize(base)}, #{colonize(index)}; _b[_i] = _b[_i] + #{inc}; return _b[_i]") +
				" end)()"

		# statements

		when "block-stat"
			{ln, stats} = n
			return (colonize(x) for x in stats).join('\n')
		when "expr-stat"
			{ln, expr} = n

			switch expr.type
				when "scope-inc-expr"
					{ln, pre, inc, value} = expr
					value = fixRef(value)
					return "#{value} = #{value} + #{inc};"
				when "static-inc-expr"
					{ln, pre, inc, base, value} = expr
					return "local _b = #{colonize(base)}; _b.#{value} = _b.#{value} + #{inc};"
				when "dyn-inc-expr"
					{ln, pre, inc, base, index} = expr
					return "local _b, _i = #{colonize(base)}, #{index}; _b[_i] = _b[_i] + #{inc};"
				when "pre-dec-op-expr", "post-dec-op-expr"
					{ln, expr} = expr
				when "scope-assign-expr" 
					{ln, value, expr} = expr
					return "#{value} = #{colonize(expr)};"
				when "static-assign-expr" 
					{ln, base, value, expr} = expr
					if not isSafe(value)	
						return colonize({type: "expr-stat", ln: ln, expr: {type: "dyn-assign-expr", ln: ln, base: base, index: {type: "str-literal", ln: ln, value: value}, expr: expr}})
					return "#{colonize(base)}.#{value} = #{colonize(expr)};"
				when "dyn-assign-expr" 
					{ln, base, index, expr} = expr
					return "#{colonize(base)}[#{colonize(index)}] = #{colonize(expr)};"
				when "call-expr", "static-method-call-expr"
					return "#{colonize(expr)};"
				when "seq-op-expr"
					{ln, left, right} = expr
					return colonize({type: "expr-stat", ln: ln, expr: left}) + "\n" + colonize({type: "expr-stat", ln: ln, expr: right})
			return "_JS._void(" + colonize(expr) + ");"
		when "ret-stat"
			{ln, expr} = n
			# wrap in conditional to allow returns to precede statements
			return "if true then return" + (if expr then " " + colonize(expr) else "") + "; end;"
		when "if-stat"
			{ln, expr, thenStat, elseStat} = n
			return "if _JS._truthy(#{colonize(expr)}) then\n#{colonize(thenStat)}\n" +
				(if elseStat then "else\n#{colonize(elseStat)}\n" else "") + "end"

		# loops

		when "while-stat"
			{ln, expr, stat} = n
			ascend = (x[1] for x in loops when x[0] != 'try' and x[1])
			name = labels.pop() or ""
			cont = stat and usesContinue(stat, name)
			loops.push(["while", name, cont])
			ret = "while #{truthy(expr)} do\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				"#{colonize(stat)}\n" +
				(if cont then "until true;\nif _c#{name} == _JS._break #{[''].concat(ascend).join(' or _c')} then break end\n" else "") +
				"end\n" +
				(if ascend.length then "if _c#{ascend.join(' or _c')} then break end\n" else '')
			loops.pop()
			return ret
		when "do-while-stat"
			{ln, expr, stat} = n
			ascend = [""].concat(x[1] for x in loops when x[0] != 'try' and x[1]).join(' or ')
			name = labels.pop() or ""
			cont = stat and usesContinue(stat, name)
			loops.push(["do", name, cont])
			ret = "repeat\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				"#{colonize(stat)}\n" +
				(if cont then "until true;\nif _c#{name} == _JS._break #{ascend} then break end\n" else "") +
				"until not #{truthy(expr)};"
			loops.pop()
			return ret
		when "for-stat"
			{ln, init, expr, step, stat} = n
			expr = {type: "boolean-literal", ln: ln, value: true} unless expr
			ascend = [""].concat(x[1] for x in loops when x[0] != 'try' and x[1]).join(' or ')
			name = labels.pop() or ""
			cont = stat and usesContinue(stat, name)
			loops.push(["for", name, cont])
			ret = (if init then (if init.type == "var-stat" then colonize(init) else colonize({type: "expr-stat", ln: ln, expr: init}) + "\n") else "") +
				"while #{truthy(expr)} do\n" +
				(if cont then "local _c#{name} = nil; repeat\n" else "") +
				colonize(stat) + "\n" +
				(if cont then "until true;\n" else "") +
				(if step then colonize({type: "expr-stat", ln: step.ln, expr: step}) + "\n" else "") +
				# _cname = _JS._break OR ANYTHING ABOVE IT ~= nil then...
				(if cont then "if _c#{name} == _JS._break #{ascend} then break end\n" else "") + 
				"end"
			loops.pop()
			return ret
		when "for-in-stat"
			{ln, isvar, value, expr, stat} = n
			return "for #{value},_v in pairs(#{colonize(expr)}) do\n#{colonize(stat)}\nend"
		when "switch-stat"
			{ln, expr, cases} = n
			name = labels.pop() or ""
			loops.push(["switch", name, false])
			ret = "repeat\n" +
				(if cases.length then ("local _#{i}#{if v then ' = ' + colonize(v) else ''}; " for i, [v, _] of cases).join('') else '') +
				"local _r = #{colonize(expr)};\n" +
				(for i, [_, stats] of cases
					if _?
						"if _r == _#{i} then\n" + (colonize(x) for x in stats).concat(if cases[Number(i)+1] and (not stats.length or stats[-1..][0].type != "break-stat") then ["_r = _#{Number(i)+1};"] else []).join("\n") + "\nend"
					else
						(colonize(x) for x in stats).join("\n")
				).join("\n") + "\n" +
				"until true"
			loops.pop()
			return ret

		when "throw-stat"
			{ln, expr} = n
			return "error(#{colonize(expr)});"
		when "try-stat"
			{ln, tryStat, catchBlock, finallyStat} = n
			l = loops.push(["try", null])-1
			ret = """
local _e = nil
local _s, _r = xpcall(function ()
        #{colonize(tryStat)}
		#{if tryStat.stats[-1..][0].type != 'ret-stat' then "return _JS._cont" else ""}
    end, function (err)
        _e = err
    end)
if _s == false then
    #{if catchBlock then catchBlock.value + " = _e;\n" + colonize(catchBlock.stat) else ""}
#{if finallyStat then colonize(finallyStat) else ""}
elseif _r == _JS._break then
#{if loops[-2..-1][0]?[1] in [null, "try"] then "return _JS._break;" else "break;" }
elseif _r ~= _JS._cont then
        return _r
end"""
			loops.pop()
			return ret
		when "var-stat"
			{ln, vars} = n
			# vars already declared, just assign here
			return ("#{fixRef(v.value)} = #{colonize(v.expr)};" for v in vars when v.expr).join(' ') + '\n'
		when "defn-stat"
			{ln, closure} = n
			return "#{fixRef(closure.name)} = (" + colonize(closure) + ");\n"
		when "label-stat"
			{ln, name, stat} = n
			labels.push(name)
			#TODO change stat to do { } while(false) unless of certain type;
			# this makes this labels array work
			ret = "#{colonize(stat)}"
			labels.pop()
			return ret
		when "break-stat"
			{ln, label} = n
			label = label or (x for x in loops when loops[0] != 'try')[-1..][0]?[1] or ""
			return "_c#{label} = _JS._break; " +
				(if loops[-1..][0][0] == "try" then "return _JS._break;" else "break;")
		when "continue-stat"
			#TODO _c down the stack is false until the main one
			{ln, label} = n
			label = label or (x for x in loops when loops[0] != 'try')[-1..][0]?[1] or ""
			return "_c#{label} = _JS._cont; " +
				(if loops[-1..][0][0] == "try" then "return _JS._break;" else "break;")

		# fallback

		else
			console.log("[ERROR] Undefined compile: " + n.type)
			return "####{n}###"


##########################
###########################
###########################

code = fs.readFileSync(process.argv[2...][0], 'utf-8')

mask = ['string', 'math']
locals = ['this', 'Object', 'Array', 'String', 'Math', 'require', 'print']

console.log "local _JS = require('colony-js');"
console.log "local #{mask.join(', ')} = #{('nil' for k in mask).join(', ')};"
console.log "local #{locals.join(', ')} = #{('_JS.'+k for k in locals).join(', ')};"
console.log "local _exports = {}; local exports = _exports;"
console.log ""
console.log colonize(jast.parse(code))
console.log ""
console.log "return _exports;"
