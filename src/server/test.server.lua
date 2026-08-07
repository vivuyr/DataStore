local Players = game:GetService("Players")
local DataStore = require(script.Parent.DataStore)
local DataStoreTypes = require(script.Parent.DataStoreTypes)
local store = DataStore.New("PlayerData", { Coins = 0 })
DataStore.Settings.WaitForSecurity = 1
DataStore.Settings.Errors.All = true
Players.PlayerAdded:Connect(function(player)
	local profile = store.StartSessionAsync(player)
	local s = DataStore.GetStore("PlayerData").Functions
	local data = s:GetLoadedProfiles()
	print(data)
end)
Players.PlayerRemoving:Connect(function(player)
	--DataStore.Stores["PlayerData"][player.UserId]
	print(store:GetData(player))
end)
--DataStore.Start({ { Store = store } })
