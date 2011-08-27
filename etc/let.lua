for i=1,10 do
local _c0 = true
repeat
	print('i=' .. i)

	for j=1,10 do
	local _c1 = true
	repeat
		print('j='..j)
		_c0,_c1 = false, false; break
	until false
	if not _c1 then break end
	end
	if not _c0 then break end

	print('lose')
until false
if not _c0 then break end
end
