--!strict

local TaskScrubber = require(script.Parent:WaitForChild("TaskScrubber"))

local ScopeRegistry = {}
ScopeRegistry.__index = ScopeRegistry

export type ScopeRegistry = typeof(setmetatable({
	_scopes = {} :: { [string | number]: TaskScrubber.TaskScrubber },
}, ScopeRegistry))

function ScopeRegistry.new(): ScopeRegistry
	local self = {
		_scopes = {},
	}
	return setmetatable(self, ScopeRegistry) :: any
end

function ScopeRegistry:GetScope(scopeId: string | number): TaskScrubber.TaskScrubber
	local scope = self._scopes[scopeId]
	if not scope then
		scope = TaskScrubber.new()
		self._scopes[scopeId] = scope
	end
	return scope
end

function ScopeRegistry:HasScope(scopeId: string | number): boolean
	return self._scopes[scopeId] ~= nil
end

function ScopeRegistry:DestroyScope(scopeId: string | number)
	local scrubber = self._scopes[scopeId]
	if scrubber then
		self._scopes[scopeId] = nil
		(scrubber :: any):Destroy()
	end
end

function ScopeRegistry:DestroyAll()
	local scopes = self._scopes
	self._scopes = {}
	for _, scrubber in pairs(scopes) do
		(scrubber :: any):Destroy()
	end
end

return ScopeRegistry
