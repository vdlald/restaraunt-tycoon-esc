--!strict

function defineClass(className: string, inheritance): table
	local Class = {}
	Class.ClassName = className

	Class.__index = Class
	if inheritance then
		Class = setmetatable(Class, { __index = inheritance })
	end

	return Class
end

return {
	defineClass = defineClass,
}
