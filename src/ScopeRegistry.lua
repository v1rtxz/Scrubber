--!strict
local TaskScrubber = require(script.Parent:WaitForChild("TaskScrubber"))
local ScopeRegistry = {}
ScopeRegistry.__index = ScopeRegistry
export type ScopeRegistry = typeof(setmetatable({
	_scopes = {} :: { [string | number]: any },
}, ScopeRegistry))
function ScopeRegistry.new(): ScopeRegistry
	local self = {
		_scopes = {},
	}
	return setmetatable(self, ScopeRegistry) :: any
end
function ScopeRegistry:GetScope(scopeId: string | number): any
	assert(type(scopeId) == "string" or type(scopeId) == "number", "[ScopeRegistry] Invalid Scope ID")
	if not self._scopes[scopeId] then
		self._scopes[scopeId] = TaskScrubber.new()
	end
	return self._scopes[scopeId]
end
function ScopeRegistry:HasScope(scopeId: string | number): boolean
	return self._scopes[scopeId] ~= nil
end
function ScopeRegistry:DestroyScope(scopeId: string | number)
	local scrubber: any = self._scopes[scopeId]
	if scrubber then
		self._scopes[scopeId] = nil
		scrubber:Destroy()
	end
end
function ScopeRegistry:DestroyAll()
	local scopeIds = {}
	for scopeId in pairs(self._scopes) do
		table.insert(scopeIds, scopeId)
	end
	for _, scopeId in ipairs(scopeIds) do
		self:DestroyScope(scopeId)
	end
end
return ScopeRegistry
