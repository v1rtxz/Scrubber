# Scrubber

<div align="center">

<img src="https://github.com/v1rtxz/Scrubber/blob/main/Logo.png?raw=true" alt="Scrubber Logo" width="200" />

**A fast, easy-to-use memory cleanup and lifecycle management framework for Luau.**

[![License](https://img.shields.io/badge/license-MIT-1f6feb)](https://github.com/v1rtxz/Scrubber/blob/main/LICENSE)
[![Luau](https://img.shields.io/badge/language-Luau-1f6feb)](https://luau-lang.org/)
[![Docs](https://img.shields.io/badge/docs-DOCUMENTATION.md-1f6feb)](https://github.com/v1rtxz/Scrubber/blob/main/DOCUMENTATION.md)
[![Setup](https://img.shields.io/badge/setup-SETUP.md-1f6feb)](https://github.com/v1rtxz/Scrubber/blob/main/SETUP.md)


</div>

---

Scrubber helps you keep track of things that need cleaning up later, like connections threads instances and custom callbacks, instead of remembering to disconnect and destroy everything by hand you hand those things to Scrubber and let it handle the teardown

It's small, it has no dependencies, and it stays out of your way once your code is running

This is a hobby project, it's still being built so expect things to change

## Why use it

Most leaks in Luau come from the same place, something gets connected or created and the code that was supposed to clean it up gets lost or never runs, Scrubber gives all of that one home

- **One place to track everything.** Connections threads instances and functions all go into a scrubber
- **Good defaults.** Connections get disconnected instances get destroyed threads get cancelled and functions get called so you don't have to write that every time
- **Scopes for lifetimes.** Player scopes clean themselves up when a player leaves and custom scopes for rounds or minigames live until you destroy them
- **Safe teardown.** Cleanup runs safely so one broken item can't stop everything else from being released

## How it works

Scrubber is built from three small pieces

| Piece | What it does |
|---|---|
| **TaskScrubber** | The core tracker, you add items to it and it knows how to clean each one up |
| **ScopeRegistry** | Keeps named scopes around like player scopes or round scopes |
| **ScrubberService** | The public entry point, creates scrubbers hands out scopes and hooks up player lifecycle events |

### Usage at a glance

```lua
-- 1. standalone scrubbers
-- good for one-off things you want cleaned up later
local scrubber = ScrubberService.CreateScrubber()
scrubber:Add(workspace.Part)
scrubber:Destroy()

-- 2. player scopes
-- these clean themselves up when the player leaves
local playerScope = ScrubberService.GetPlayerScope(player)
playerScope:Add(workspace.ChildAdded:Connect(function() end))

-- 3. custom scopes
-- good for rounds or minigames, you destroy them when you're done
local roundScope = ScrubberService.GetScope("Round_1")
roundScope:Add(timerThread)
ScrubberService.DestroyScope("Round_1")
```

### TaskScrubber methods

These are available on any scrubber or scope

- `:Add(taskItem, customMethod?, key?, silentOverwrite?)` adds an item to track, if you reuse a key and set `silentOverwrite` to true the old item is dropped without running its cleanup
- `:Get(key)` returns an item by its key
- `:Remove(key)` cleans up one item right away
- `:LinkToInstance(instance)` cleans up the whole scope if the instance is destroyed
- `:Cleanup()` and `:Destroy()` clean up everything in the scope

## Status

Scrubber is in beta development, things may be a bit broken still or a few fixes and new changes might come out there and there.

## Links

- **Documentation:** [DOCUMENTATION.md](https://github.com/v1rtxz/Scrubber/blob/main/DOCUMENTATION.md)
- **License:** [LICENSE](https://github.com/v1rtxz/Scrubber/blob/main/LICENSE)
- **Roblox Store:** [ScrubberService](https://create.roblox.com/store/asset/74188375071458/ScrubberService)


## Credits

Made by **[Vortex](https://www.roblox.com/users/2816954293/profile)**.
