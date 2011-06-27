function test()
	local _cont, _e = {}, nil
	local _s, _r = xpcall(function ()
			-- try
			print ('try')

			--error({code=121})
			return 5

			--return cont
		end, function (err)
			_e = err
		end)
	if _s == false then
		-- catch
		print('Catch ')
		print(_e)
	end
	-- finally
	print('Finally')

	-- returns
	if _r ~= cont then
		return _r
	end
	
	print('More code...')
end

test()
