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

See [Installation](https://github.com/vivuyr/DataStore/blob/master/docs/Installation.md).

> [!WARNING]
> Versions older than **0.0.3** contains critical issues and is **not recommended**.
>
> Please use **0.0.3** or later.

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

- [Github](https://github.com/vivuyr/DataStore)

- [Getting started](https://github.com/vivuyr/DataStore/blob/master/docs/GettingStarted.md)
- [Installation](https://github.com/vivuyr/DataStore/blob/master/docs/Installation.md)
- [API reference](https://github.com/vivuyr/DataStore/blob/master/docs/API.md)
- [Settings](https://github.com/vivuyr/DataStore/blob/master/docs/Settings.md)
- [Types](https://github.com/vivuyr/DataStore/blob/master/docs/Types.md)
- [Error handling](https://github.com/vivuyr/DataStore/blob/master/docs/ErrorHandling.md)
- [Examples](https://github.com/vivuyr/DataStore/blob/master/docs/Examples.md)
- [Best practices](https://github.com/vivuyr/DataStore/blob/master/docs/BestPractices.md)

## License

This project is licensed under the MIT License.
