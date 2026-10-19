--!nonstrict

local TaskScrubber = {}
TaskScrubber.__index = TaskScrubber

export type CleanupMethod = string | boolean | ((item: any) -> ())
type Destructor = (any) -> ()

local TYPE_DEFAULTS: { [string]: string } = {
	["RBXScriptConnection"] = "Disconnect",
	["Instance"] = "Destroy",
	["thread"] = "cancel",
}

export type TaskScrubber = {
	_queue: { any },
	_keyedIndices: { [any]: number },
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
		_queue = {},
		_keyedIndices = {},
		IsCleaning = false,
	}
	return setmetatable(self, TaskScrubber) :: any
end

local function ResolveDestructor(taskItem: any, method: CleanupMethod?): Destructor
	if type(method) == "function" then
		return method :: Destructor
	end

	if type(taskItem) == "thread" then
		return function(item)
			task.cancel(item :: thread)
		end
	end

	if typeof(taskItem) == "RBXScriptConnection" then
		return function(item)
			(item :: RBXScriptConnection):Disconnect()
		end
	end

	if method == true and type(taskItem) == "function" then
		return function(item)
			(item :: () -> ())()
		end
	end

	if type(method) == "string" then
		local methodName = method :: string
		return function(item)
			if type(item) == "table" or typeof(item) == "Instance" then
				local func = (item :: any)[methodName]
				if type(func) == "function" then
					func(item)
				end
			end
		end
	end

	local defaultMethod = TYPE_DEFAULTS[typeof(taskItem)]
	if defaultMethod == "Disconnect" then
		return function(item)
			(item :: RBXScriptConnection):Disconnect()
		end
	elseif defaultMethod == "cancel" then
		return function(item)
			task.cancel(item :: thread)
		end
	end

	return function(item)
		if type(item) == "table" or typeof(item) == "Instance" then
			local destroyFunc = (item :: any)["Destroy"]
			if type(destroyFunc) == "function" then
				destroyFunc(item)
			end
		end
	end
end

function TaskScrubber.Add(self: TaskScrubber, taskItem: any, customMethod: CleanupMethod?, key: any?, silentOverwrite: boolean?): any
	if not taskItem then
		return nil
	end

	local destructor = ResolveDestructor(taskItem, customMethod)

	if self.IsCleaning then
		pcall(destructor :: any, taskItem)
		return taskItem
	end

	if key ~= nil then
		local existingIndex = self._keyedIndices[key]
		if existingIndex ~= nil then
			local existingItem = self._queue[existingIndex]
			local existingDestructor = self._queue[existingIndex + 1]

			if existingItem ~= false and existingDestructor then
				if not silentOverwrite then
					pcall(existingDestructor :: any, existingItem)
				else
					if type(existingItem) == "thread" then
						pcall(task.cancel, existingItem)
					end
				end
			end

			self._queue[existingIndex] = taskItem
			self._queue[existingIndex + 1] = destructor
			return taskItem
		else
			local index = #self._queue + 1
			self._queue[index] = taskItem
			self._queue[index + 1] = destructor
			self._keyedIndices[key] = index
			return taskItem
		end
	end

	local index = #self._queue + 1
	self._queue[index] = taskItem
	self._queue[index + 1] = destructor

	return taskItem
end

function TaskScrubber.Get(self: TaskScrubber, key: any): any?
	local index = self._keyedIndices[key]
	if index ~= nil then
		local item = self._queue[index]
		return item ~= false and item or nil
	end
	return nil
end

function TaskScrubber.Remove(self: TaskScrubber, key: any)
	local index = self._keyedIndices[key]
	if index ~= nil then
		self._keyedIndices[key] = nil
		local item = self._queue[index]
		local destructor = self._queue[index + 1]

		self._queue[index] = false
		self._queue[index + 1] = false

		if destructor and item ~= false then
			pcall(destructor :: any, item)
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

	local queue = self._queue
	self._queue = {}
	table.clear(self._keyedIndices)

	local i = 1
	while queue[i] ~= nil do
		local item = queue[i]
		local destructor = queue[i + 1]
		if item ~= false and destructor then
			pcall(destructor :: any, item)
		end
		i += 2
	end

	self.IsCleaning = false
end

function TaskScrubber.Destroy(self: TaskScrubber)
	self:Cleanup()
end

return TaskScrubber
