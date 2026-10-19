--!strict
local TaskScrubber = {}
TaskScrubber.__index = TaskScrubber

export type CleanupMethod = string | boolean | ((item: any) -> ())

type TaskEntry = {
	item: any,
	method: CleanupMethod,
}

local TYPE_DEFAULTS: { [string]: CleanupMethod } = {
	["RBXScriptConnection"] = "Disconnect",
	["Instance"] = "Destroy",
	["thread"] = "cancel",
	["function"] = true,
}

export type TaskScrubber = {
	_tasks: { [string | number]: TaskEntry },
	_keys: { [any]: string | number },
	_nextId: number,
	IsCleaning: boolean,

	Add: (self: TaskScrubber, taskItem: any, customMethod: CleanupMethod?, key: any?, silentOverwrite: boolean?) -> any,
	Get: (self: TaskScrubber, key: any) -> any?,
	Remove: (self: TaskScrubber, key: any) -> (),
	LinkToInstance: (self: TaskScrubber, instance: Instance) -> any,
	Cleanup: (self: TaskScrubber) -> (),
	Destroy: (self: TaskScrubber) -> (),
}

function TaskScrubber.new(): TaskScrubber
	local self = {
		_tasks = {},
		_keys = {},
		_nextId = 0,
		IsCleaning = false,
	}
	return setmetatable(self, TaskScrubber) :: any
end

local function ExecuteTask(taskItem: any, method: CleanupMethod)
	if type(method) == "function" then
		local success, err = pcall(method :: any, taskItem)
		if not success then
			warn("[TaskScrubber] Custom cleanup failed: " .. tostring(err))
		end
		return
	end

	if type(taskItem) == "thread" then
		local success, err = pcall(task.cancel, taskItem)
		if not success and err then
			warn("[TaskScrubber] Thread cancel failed: " .. tostring(err))
		end
		return
	end

	if typeof(taskItem) == "RBXScriptConnection" then
		local success, err = pcall(function()
			(taskItem :: RBXScriptConnection):Disconnect()
		end)
		if not success and err then
			warn("[TaskScrubber] Connection disconnect failed: " .. tostring(err))
		end
		return
	end

	if method == true then
		if type(taskItem) == "function" then
			local success, err = pcall(taskItem :: any)
			if not success then
				warn("[TaskScrubber] Function cleanup failed: " .. tostring(err))
			end
		end
		return
	end

	if type(method) == "string" then
		if type(taskItem) == "table" or typeof(taskItem) == "Instance" then
			local methodFunc = (taskItem :: any)[method]
			if type(methodFunc) == "function" then
				local success, err = pcall(function()
					(methodFunc :: any)(taskItem)
				end)
				if not success and err then
					warn("[TaskScrubber] Method '" .. method .. "' failed: " .. tostring(err))
				end
			else
				warn("[TaskScrubber] Method '" .. method .. "' does not exist on task item of type " .. typeof(taskItem))
			end
		else
			warn("[TaskScrubber] Cannot call method '" .. method .. "' on non-table task item.")
		end
	end
end

function TaskScrubber.Add(self: TaskScrubber, taskItem: any, customMethod: CleanupMethod?, key: any?, silentOverwrite: boolean?): any
	if not taskItem then
		return nil
	end

	local cleanupMethod: CleanupMethod
	if customMethod ~= nil then
		cleanupMethod = customMethod
	else
		cleanupMethod = TYPE_DEFAULTS[typeof(taskItem)] or "Destroy"
	end

	if self.IsCleaning then
		warn("[TaskScrubber] Add() was called while cleanup is running, so the task was executed immediately instead of being tracked.")
		ExecuteTask(taskItem, cleanupMethod)
		return taskItem
	end
	if key ~= nil then
		local existingId = self._keys[key]
		if existingId ~= nil then
			if silentOverwrite then
				self._tasks[existingId] = nil :: any
			else
				self:Remove(key)
			end
		end
	end

	self._nextId += 1
	local taskId: string | number = self._nextId

	self._tasks[taskId] = {
		item = taskItem,
		method = cleanupMethod,
	}

	if key ~= nil then
		self._keys[key] = taskId
	end

	return taskItem
end

function TaskScrubber.Get(self: TaskScrubber, key: any): any?
	local taskId = self._keys[key]
	if taskId ~= nil then
		local entry = self._tasks[taskId]
		if entry ~= nil then
			return entry.item
		end
	end
	return nil
end

function TaskScrubber.Remove(self: TaskScrubber, key: any)
	local taskId = self._keys[key]
	if taskId ~= nil then
		self._keys[key] = nil
		local entry = self._tasks[taskId]
		if entry ~= nil then
			self._tasks[taskId] = nil :: any
			ExecuteTask(entry.item, entry.method :: CleanupMethod)
		end
	end
end

function TaskScrubber.LinkToInstance(self: TaskScrubber, instance: Instance): any
	if typeof(instance) ~= "Instance" then
		return nil
	end

	local connection = instance.Destroying:Connect(function()
		self:Cleanup()
	end)

	return self:Add(connection, "Disconnect")
end

function TaskScrubber.Cleanup(self: TaskScrubber)
	if self.IsCleaning then
		return
	end
	self.IsCleaning = true

	local tasksToClean = self._tasks
	self._tasks = {}
	table.clear(self._keys)
	self._nextId = 0

	for _, entry in pairs(tasksToClean) do
		local taskEntry = entry :: TaskEntry?
		if taskEntry ~= nil then
			ExecuteTask(taskEntry.item, taskEntry.method :: CleanupMethod)
		end
	end

	self.IsCleaning = false
end

function TaskScrubber.Destroy(self: TaskScrubber)
	self:Cleanup()
end

return TaskScrubber
