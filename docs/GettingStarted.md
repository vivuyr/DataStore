# Getting Started

Create one store per data domain, then start the DataStore manager once.

```lua
local Players = game:GetService("Players")
local DataStore = require(game.ServerScriptService.Server.DataStore)

local playerStore = DataStore.New("PlayerData", {
	Coins = 0,
	Level = 1,
})

DataStore.Start({
	{ Store = playerStore },
})

Players.PlayerAdded:Connect(function(player)
	local session = playerStore:WaitForSession(player)
	if not session then
		return
	end

	session.Profile.Data.Coins += 10
	session:Save("Normal")
end)
```

`New` creates a named store from the template. `Start` connects player lifecycle events and starts sessions for current and subsequently added players. `WaitForSession` waits for the session (subject to `Settings.WaitTimeout`), while `GetSession` returns immediately. `Profile.Data` is the mutable player data. `Save` returns `true` when it schedules a save and `nil` while its cooldown prevents one.
