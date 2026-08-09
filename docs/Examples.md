# Examples

## Basic player data

```lua
local Players = game:GetService("Players")
local DataStore = require(game.ServerScriptService.Server.DataStore)
local store = DataStore.New("PlayerData", { Coins = 0 })

DataStore.Start({ { Store = store } })

Players.PlayerAdded:Connect(function(player)
	local data = store.WaitForData(player)
	if data then
		data.Coins += 1
	end
end)
```

## Multiple stores

```lua
local inventory = DataStore.New("Inventory", { Items = {} })
local settings = DataStore.New("Settings", { Music = true })
DataStore.Start({
	{ Store = inventory },
	{ Store = settings },
})
```

## Manual session start

```lua
local session = store.StartSessionAsync(player, { Steal = false })
if session then
	print(session.Profile.Key)
end
```

## Using `WaitForProfile`

```lua
local profile = store.WaitForProfile(player)
if profile then
	profile.Data.Coins += 25
end
```

## Using `WaitForData`

```lua
local data = store.WaitForData(player)
if data then
	print("Coins:", data.Coins)
end
```

## Checking sessions

```lua
if store.HasSession(player) then
	local session = store.GetSession(player)
	if session then
		print(session.Profile.Data.Coins)
	end
end
```

## Saving profiles

```lua
local session = store.GetSession(player)
if session then
	local saved = session.Save("High")
	print("Save requested:", saved == true)
end

local allSaved = store.SaveAll()
```

## Accessing ProfileStore directly

```lua
local store = DataStore.New("PlayerData", { Coins = 0 })
local profileStore = store.Store
local historicalProfile = profileStore:GetAsync("12345")
```

The wrapper only types and exposes the ProfileStore reference; the behavior of direct ProfileStore calls comes from that dependency.

## Custom settings

```lua
DataStore.Settings.Logging.All = false
DataStore.Settings.Logging.Important = true
DataStore.Settings.KickIfSessionLost = true
DataStore.Settings.SessionLostMessage = "Your data session ended. Please rejoin."
DataStore.Settings.ShutdownIfConnectionFails = true
DataStore.Settings.WaitTimeout = 15
DataStore.Settings.CriticalToggleCallback = function()

print("Critical")

end
```
