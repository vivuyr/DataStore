# DataStore

DataStore is a typed Roblox Luau wrapper around ProfileStore. It creates named profile stores, manages player sessions, exposes typed data accessors, and provides throttled save helpers.

## Features

- Typed profile templates and data access.
- Player session start and end helpers.
- Waiting and non-blocking access APIs.
- Per-session and all-session save helpers.
- Session-loss kicking and connection-failure handling.
- Direct access to the underlying ProfileStore module.

## Why this library exists

ProfileStore provides the persistence primitive. This library adds a small application-facing layer for player-based keys, session bookkeeping, settings, and common access patterns.

## Installation

See [Installation](docs/Installation.md).

## Quick example

```lua
local Players = game:GetService("Players")
local DataStore = require(game.ServerScriptService.Server.DataStore)

local playerStore = DataStore.New("PlayerData", { Coins = 0 })
DataStore.Start({ { Store = playerStore } })

Players.PlayerAdded:Connect(function(player)
	local profile = playerStore.WaitForProfile(player)
	if profile then
		print(profile.Data.Coins)
	end
end)
```

## Documentation

- [Getting started](docs/GettingStarted.md)
- [Installation](docs/Installation.md)
- [API reference](docs/API.md)
- [Settings](docs/Settings.md)
- [Types](docs/Types.md)
- [Error handling](docs/ErrorHandling.md)
- [Examples](docs/Examples.md)
- [Best practices](docs/BestPractices.md)

## License

This repository does not declare a license in the source or project metadata. Add a license before redistributing it.
