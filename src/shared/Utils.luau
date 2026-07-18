--!strict

local Utils = {}

function Utils:safeCall<T>(label: string, fn: () -> T): (T?, boolean)
	local ok, resOrErr = xpcall(fn, debug.traceback)
	if not ok then
		warn(("%s failed\n%s"):format(label, resOrErr))
		return nil, false
	end
	return resOrErr, true
end

return Utils
