# Scrubber Documentation

This is the full documentation for Scrubber, if you just want the short version check the [README](https://github.com/v1rtxz/Scrubber/blob/main/README.md) this page goes into detail about how everything works and how to use it more straightforward

> **Note:** Scrubber is still in early development, things may change as it gets built out

---

## What Scrubber is

Scrubber is a memory cleanup and lifecycle management framework for Luau, it gives you one place to track things that need to be cleaned up later like connections threads instances and custom callbacks and it handles the cleanup for you when the time comes

Instead of writing disconnect and destroy calls all over your code and hoping you didn't miss one you hand those things to Scrubber and let it do the work

---

## The pieces

Scrubber is made up of three small pieces that work together

### TaskScrubber

This is the core tracker, it holds onto your items and knows how to clean each one up and everything else in Scrubber is built on top of it

You can create one directly if you just want a standalone scrubber

```lua
local scrubber = ScrubberService.CreateScrubber()
```

### ScopeRegistry

This keeps named scopes around so you can grab them later, player scopes and round scopes both live here and you usually won't touch it directly since `ScrubberService` handles it for you

### ScrubberService

This is the public entry point, it creates scrubbers hands out scopes and hooks up player lifecycle events and most of the time this is the only piece you'll interact with

---

## Getting started

### Creating a standalone scrubber

If you just want to track a few things and clean them up later make a scrubber and add items to it

```lua
local scrubber = ScrubberService.CreateScrubber()

scrubber:Add(workspace.Part)
scrubber:Add(someConnection)

-- when your done with everything
scrubber:Destroy()
```

### Using player scopes

Player scopes clean themselves up automatically when the player leaves, this is handy for anything that should only live as long as the player is in the game

```lua
local playerScope = ScrubberService.GetPlayerScope(player)

playerScope:Add(workspace.ChildAdded:Connect(function(child)
    -- do something
end))
```

When the player leaves the scope is destroyed and everything in it is cleaned up and you don't have to do anything else

### Using custom scopes

Custom scopes are good for rounds minigames or anything else with a clear start and end, you create them by name and destroy them when you're done

```lua
local roundScope = ScrubberService.GetScope("Round_1")

roundScope:Add(timerThread)
roundScope:Add(someConnection)

-- when the round ends
ScrubberService.DestroyScope("Round_1")
```

---

## TaskScrubber methods

These methods are available on any scrubber or scope object

### `:Add(taskItem, customMethod?, key?, silentOverwrite?)`

Adds an item to track, when the scrubber is destroyed or cleaned up the item will be cleaned up using the appropriate method

- `taskItem` is the thing you want to track, it can be a connection an instance a thread a function or a table
- `customMethod` lets you override how the item gets cleaned up, it can be a string (a method name) `true` (call it as a function) or a function (a custom cleanup callback)
- `key` lets you give the item a name so you can grab it later with `:Get` or remove it early with `:Remove`
- `silentOverwrite` controls what happens if you reuse a key, if it's `true` the old item is dropped without running its cleanup and if it's `false` or not set the old item is cleaned up normally first

If you don't pass a `customMethod` Scrubber picks a sensible default based on the item's type

| Type | Default cleanup |
|---|---|
| `RBXScriptConnection` | `Disconnect` |
| `Instance` | `Destroy` |
| `thread` | `cancel` |
| `function` | Called directly |

### `:Get(key)`

Returns the item stored under that key or `nil` if there isn't one

### `:Remove(key)`

Cleans up the item stored under that key right away and removes it from the scrubber

### `:LinkToInstance(instance)`

Ties the whole scope to an instance, if that instance is destroyed the scope cleans itself up automatically, useful when a scope's lifetime should match something in the world

```lua
local scope = ScrubberService.CreateScrubber()
scope:LinkToInstance(someModel)
-- when someModel is destroyed, scope cleans itself up
```

### `:Cleanup()` and `:Destroy()`

These both clean up everything in the scope, `:Destroy()` just calls `:Cleanup()` for you so they do the same thing and everything tracked gets cleaned up safely so one broken item won't stop the rest

---

## ScrubberService methods

These are the methods on `ScrubberService` itself

### `ScrubberService.CreateScrubber()`

Makes a new standalone scrubber, good for one-off things you want cleaned up later

### `ScrubberService.GetScope(scopeId)`

Returns the scope with that name, creating it if it doesn't exist yet, use this for rounds minigames or anything else you want to manage by name

### `ScrubberService.HasScope(scopeId)`

Returns `true` if a scope with that name exists and `false` otherwise

### `ScrubberService.DestroyScope(scopeId)`

Cleans up and removes the scope with that name, everything tracked inside it gets cleaned up

### `ScrubberService.GetPlayerScope(player)`

Returns the scope tied to that player, creating it if it doesn't exist yet, the scope cleans itself up automatically when the player leaves

If you call this after the player has already left Scrubber will warn you since there's nothing left to trigger the cleanup, in that case destroy the scope manually with `DestroyScope`

### `ScrubberService.HasPlayerScope(player)`

Returns `true` if that player has a scope and `false` otherwise

### `ScrubberService.Init()`

Starts up `ScrubberService`, this hooks into `Players.PlayerRemoving` so player scopes clean themselves up and it creates scopes for anyone already in the game, it's safe to call more than once but only the first call does anything

You only need to call this once usually from a server script early on

```lua
ScrubberService.Init()
```

---

## Cleanup behavior

A few things worth knowing about how cleanup works

- **Everything runs safely.** Each cleanup is wrapped so one failure doesn't stop the rest from running, if something goes wrong you'll get a warning instead of an error
- **Adding during cleanup is handled.** If you try to `:Add()` something while a scrubber is in the middle of cleaning up it gets cleaned up right away instead of being tracked, this stops things from slipping through
- **Cleanup is one-way.** Once a scrubber is cleaned up it's empty, you can keep adding to it and it'll work again but everything it held is gone

---

## A practical example

Here's a small example of a round system that uses Scrubber to keep things tidy

```lua
local ScrubberService = require(game.ServerScriptService.ScrubberService)
ScrubberService.Init()

local function startRound(roundId)
    local scope = ScrubberService.GetScope("Round_" .. roundId)

    -- track a timer thread
    local timerThread = task.spawn(function()
        while true do
            task.wait(1)
            -- tick
        end
    end)
    scope:Add(timerThread)

    -- track connections
    scope:Add(workspace.ChildAdded:Connect(function(child)
        -- handle something
    end))

    -- track an instance
    local roundFolder = Instance.new("Folder")
    roundFolder.Name = "Round_" .. roundId
    roundFolder.Parent = workspace
    scope:Add(roundFolder)
end

local function endRound(roundId)
    ScrubberService.DestroyScope("Round_" .. roundId)
    -- everything tracked in that scope is now cleaned up
end
```

---

## Status

Scrubber is in early development, the source and this documentation are still being written so nothing is final, if something looks off or doesn't work the way this page says that's a bug and it'll get fixed as things get built out

---

## Links

- **Repository:** [github.com/v1rtxz/Scrubber](https://github.com/v1rtxz/Scrubber)
- **README:** [README.md](https://github.com/v1rtxz/Scrubber/blob/main/README.md)
- **License:** [LICENSE](https://github.com/v1rtxz/Scrubber/blob/main/LICENSE)

