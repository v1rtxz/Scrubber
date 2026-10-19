--!strict

--[[
================================================================================
                                SCRUBBER SERVICE
                                   BY VORTEX
================================================================================
A central service for cleaning up memory, preventing leaks, and managing
lifecycles across the server. It keeps track of things that need to be
released later so you don't have to remember to do it yourself.
Who even wants to do that lol.

--------------------------------------------------------------------------------
IMPORTANT NOTICE:
--------------------------------------------------------------------------------

Make sure to put this in ServerScriptService or somewhere safe, and the only
way to use it is by requiring it with a server script.

If you're not a professional at editing code then I advise you to NOT try
doing so.

If you are stuck, go onto the documentation docs in the links section.
--------------------------------------------------------------------------------
USAGE:
--------------------------------------------------------------------------------

1. Standalone scrubbers (good for one-off things):
   local scrubber = ScrubberService.CreateScrubber()
   scrubber:Add(workspace.Part)
   scrubber:Destroy()

2. Player scopes (clean themselves up when the player leaves):
   local playerScope = ScrubberService.GetPlayerScope(player)
   playerScope:Add(workspace.ChildAdded:Connect(function() end))

3. Custom scopes (good for rounds or minigames):
   local roundScope = ScrubberService.GetScope("Round_1")
   roundScope:Add(timerThread)
   ScrubberService.DestroyScope("Round_1")

--------------------------------------------------------------------------------
TASK SCRUBBER METHODS:
These work on any scrubber or scope.
--------------------------------------------------------------------------------

- :Add(taskItem, customMethod?, key?, silentOverwrite?)
  Adds an item to track. If you reuse a key and set silentOverwrite to true,
  the old item is dropped without running its cleanup.

- :Get(key)
  Returns an item by its key.

- :Remove(key)
  Cleans up one item right away.

- :LinkToInstance(instance)
  Cleans up the whole scope if the instance is destroyed.

- :Cleanup() and :Destroy()
  Cleans up everything in the scope safely.

--------------------------------------------------------------------------------
LINKS:
--------------------------------------------------------------------------------

- Docs: https://github.com/v1rtxz/Scrubber/blob/main/DOCUMENTATION.md
- Repo: https://github.com/v1rtxz/Scrubber
================================================================================
]]

local Players = game:GetService("Players")
local TaskScrubber = require(script.TaskScrubber)
local ScopeRegistry = require(script.ScopeRegistry)
local VersionTracker = require(script.VersionTracker)

local ScrubberService = {}
local GlobalScopes = ScopeRegistry.new()
local isInitialized: boolean = false

function ScrubberService.CreateScrubber(): TaskScrubber.TaskScrubber
	return TaskScrubber.new()
end

function ScrubberService.GetScope(scopeId: string | number): TaskScrubber.TaskScrubber
	return GlobalScopes:GetScope(scopeId)
end

function ScrubberService.HasScope(scopeId: string | number): boolean
	return GlobalScopes:HasScope(scopeId)
end

function ScrubberService.DestroyScope(scopeId: string | number)
	GlobalScopes:DestroyScope(scopeId)
end

function ScrubberService.GetPlayerScope(player: Player): TaskScrubber.TaskScrubber
	return GlobalScopes:GetScope("Player_" .. player.UserId)
end

function ScrubberService.HasPlayerScope(player: Player): boolean
	return GlobalScopes:HasScope("Player_" .. player.UserId)
end

local function OnPlayerRemoving(player: Player)
	ScrubberService.DestroyScope("Player_" .. player.UserId)
end

function ScrubberService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		ScrubberService.GetPlayerScope(player)
	end

	VersionTracker.Run()
end

print("[ ScrubberService loaded ]")

return ScrubberService
