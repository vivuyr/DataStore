local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreTypes = require(ServerScriptService.Server.DataStoreTypes)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

export type Profile<T> = {
	Data: T & JSONAcceptable,
	LastSavedData: T & JSONAcceptable,
	FirstSessionTime: number,
	SessionLoadCount: number,
	Session: { PlaceId: number, JobId: string }?,
	RobloxMetaData: JSONAcceptable,
	UserIds: { number },
	KeyInfo: DataStoreKeyInfo,
	OnSave: { Connect: (self: any, listener: () -> ()) -> { Disconnect: (self: any) -> () } },
	OnLastSave: {
		Connect: (
			self: any,
			listener: (reason: "Manual" | "External" | "Shutdown") -> ()
		) -> { Disconnect: (self: any) -> () },
	},
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> { Disconnect: (self: any) -> () } },
	OnAfterSave: {
		Connect: (
			self: any,
			listener: (last_saved_data: T & JSONAcceptable) -> ()
		) -> { Disconnect: (self: any) -> () },
	},
	ProfileStore: JSONAcceptable,
	Key: string,

	IsActive: (self: any) -> boolean,
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	AddUserId: (self: any, user_id: number) -> (),
	RemoveUserId: (self: any, user_id: number) -> (),
	MessageHandler: (self: any, fn: (message: JSONAcceptable, processed: () -> ()) -> ()) -> (),
	Save: (self: any) -> (),
	SetAsync: (self: any) -> (),
}

type VersionQuery<T> = {
	NextAsync: (self: any) -> Profile<T>?,
}

type ProfileStoreStandard<T> = {
	Name: string,
	StartSessionAsync: (self: any, profile_key: string, params: { Steal: boolean? }) -> Profile<T>?,
	MessageAsync: (self: any, profile_key: string, message: JSONAcceptable) -> boolean,
	GetAsync: (self: any, profile_key: string, version: string?) -> Profile<T>?,
	VersionQuery: (
		self: any,
		profile_key: string,
		sort_direction: Enum.SortDirection?,
		min_date: DateTime | number | nil,
		max_date: DateTime | number | nil
	) -> VersionQuery<T>,
	RemoveAsync: (self: any, profile_key: string) -> boolean,
}

type ProfileStore<T> = {
	Mock: ProfileStoreStandard<T>,
} & ProfileStoreStandard<T>

type SessionParams = { Steal: boolean? }

type ProfileSession<T> = {
	Profile: Profile<T>,
	EndSession: () -> (),
}

type StartSessionAsync<T> = (player: Player, params: SessionParams?) -> ProfileSession<T>?

type DataStoreFunctions<T> = {
	StartSessionAsync: StartSessionAsync<T>?,
	WaitForSession: ((player: Player) -> ProfileSession<T>?)?,
	WaitForProfile: ((player: Player) -> Profile<T>?)?,
	WaitForData: ((player: Player) -> JSONAcceptable?)?,
	GetSession: ((player: Player) -> ProfileSession<T>?)?,
	GetProfile: ((player: Player) -> Profile<T>?)?,
	GetData: ((player: Player) -> JSONAcceptable?)?,
	HasSession: ((player: Player) -> boolean)?,
}

type DataStoreDefinition<T> = {
	Store: ProfileStore<T>,
	StartSessionAsync: StartSessionAsync<T>,
	WaitForSession: (player: Player) -> ProfileSession<T>?,
	WaitForProfile: (player: Player) -> Profile<T>?,
	WaitForData: (player: Player) -> JSONAcceptable?,
	GetSession: (player: Player) -> ProfileSession<T>?,
	GetProfile: (player: Player) -> Profile<T>?,
	GetData: (player: Player) -> JSONAcceptable?,
	HasSession: (player: Player) -> boolean,
}

type StartConfiguration = {
	Store: DataStoreDefinition<any>,
	Params: SessionParams?,
}

type StoreName = DataStoreTypes.StoreName | string

type New<T> = (storeName: StoreName, template: JSONAcceptable) -> DataStoreDefinition<T>

type ProfileModule = typeof(ProfileStore)

export type DataStoreState = "NotReady" | "Ready"

type StoreInfo = {
	Store: ProfileStore<any>,
	Functions: DataStoreFunctions<any>,
	Keys: { [number]: ProfileSession<any> },
}

export type Store = {
	[StoreName]: StoreInfo,
}

export type Data = {
	ProfileStore: ProfileModule,
	DataStoreState: DataStoreState,
	Settings: {
		Errors: {
			All: boolean,
			Important: boolean,
		},
		KickIfSessionLost: boolean,
		WaitForSecurity: number?,
	},

	Start: (stores: { StartConfiguration }) -> (),
	New: <T>(storeName: StoreName, template: JSONAcceptable) -> DataStoreDefinition<T>,
	GetStore: (storeName: StoreName) -> StoreInfo?,
}

local Stores: Store = {}

--[[
local DataStore = {
	ProfileStore = ProfileStore,
	DataStoreState = "NotReady",
	Settings = {
		Errors = {
			All = false,
			Important = true,
		},
	},
}
	--]]

local DataStore = {} :: Data

DataStore["ProfileStore"] = ProfileStore
DataStore["DataStoreState"] = "NotReady"
DataStore["Settings"] = {
	Errors = {
		All = false,
		Important = true,
	},
	KickIfSessionLost = true,
	WaitForSecurity = 10,
}

local STARTED: boolean = false

local function LogError(text, setting)
	local errorsAll = DataStore.Settings.Errors.All
	if setting or errorsAll then
		error(text)
	else
		warn(text)
	end
end

local function IsReady(): ()
	if DataStore.DataStoreState == "Ready" then
		return
	end
	local status = ProfileStore.DataStoreState
	if status ~= "Access" then
		local ready = false
		for _i = 1, 10 do
			task.wait(1)
			if ProfileStore.DataStoreState == "Access" then
				ready = true
				break
			end
		end
		if not ready then
			LogError("[DataStore] Unable to connect to DataStore", DataStore.Settings.Errors.Important)
		end
	end
	DataStore.DataStoreState = "Ready"
end

function DataStore.Start(stores: { StartConfiguration }): ()
	if STARTED then
		LogError("[DataStore] DataStore cannot be started several times")
		return
	end
	STARTED = true
	IsReady()

	Players.PlayerAdded:Connect(function(player)
		for _, store in ipairs(stores) do
			local _session = store.Store.StartSessionAsync(player, store.Params or {})
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local key = player.UserId
		for _, store in pairs(Stores) do
			if store.Keys[key] ~= nil then
				store.Keys[key]:EndSession()
			end
		end
	end)
end

function DataStore.New<T>(storeName: StoreName, template: JSONAcceptable): DataStoreDefinition<T>
	local function NewStore<T>(storeName: StoreName, template: JSONAcceptable): DataStoreDefinition<T>
		IsReady()
		local store = ProfileStore.New(storeName, template)

		Stores[storeName] = {
			Store = store,
			Functions = {},
			Keys = {},
		}

		local StoreInfo = Stores[storeName]

		local Functions = StoreInfo.Functions

		local StartSessionAsync = function(player: Player, params: SessionParams?): ProfileSession<T>?
			local key = player.UserId
			local profile = store:StartSessionAsync(tostring(key), params or {})
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Unable to start session"):format(text))
				return profile
			end
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			local EndSession = function(): ()
				profile:EndSession()
				StoreInfo.Keys[key] = nil
			end

			StoreInfo.Keys[key] = { Profile = profile, EndSession = EndSession }
			return {
				Profile = profile,
				EndSession = EndSession,
			}
		end
		Functions.StartSessionAsync = StartSessionAsync

		local WaitForSession = function(player: Player): ProfileSession<T>?
			local key = player.UserId
			local keys = StoreInfo.Keys
			local session = keys and StoreInfo.Keys[key]
			if not session then
				if DataStore.Settings.WaitForSecurity then
					local Security = DataStore.Settings.WaitForSecurity
					if Security <= 0 then
						LogError(
							"[DataStore] WaitForSessionSecurity is disabled, because has wrong number: Security <= 0"
						)
					else
						for _i = 1, Security do
							task.wait(1)
							keys = StoreInfo.Keys
							session = keys and StoreInfo.Keys[key]
							if session then
								return session
							end
						end
						local text = player.Name or "Unknown"
						LogError(("[DataStore] Waiting for %s session took too long"):format(text))
						return
					end
				end
				while true do
					task.wait(1)
					keys = StoreInfo.Keys
					session = keys and StoreInfo.Keys[key]
					if session then
						return session
					end
				end
			end
			return session
		end

		Functions.WaitForSession = WaitForSession

		local WaitForProfile = function(player: Player): Profile<T>?
			local session = WaitForSession(player)
			if not session then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] Waiting for %s profile took too long"):format(text))
				return
			end
			return session.Profile
		end

		Functions.WaitForProfile = WaitForProfile

		local WaitForData = function(player: Player): JSONAcceptable?
			local profile = WaitForProfile(player)
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Data not found."):format(text))
				return
			end
			return profile.Data
		end

		Functions.WaitForData = WaitForData

		local GetSession = function(player: Player): ProfileSession<T>?
			local key = player.UserId
			local keys = StoreInfo.Keys
			local session = keys and StoreInfo.Keys[key]
			if not session then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Session not found."):format(text))
				return
			end
			return session
		end

		Functions.GetSession = GetSession

		local GetProfile = function(player: Player): Profile<T>?
			local session = StoreInfo.Functions.GetSession(player)
			if not session then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Profile not found."):format(text))
				return
			end
			return session.Profile
		end

		Functions.GetProfile = GetProfile

		local GetData = function(player: Player): JSONAcceptable?
			local profile = GetProfile(player)
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Data not found."):format(text))
				return
			end
			return profile.Data
		end

		Functions.GetData = GetData

		local GetLoadedProfiles = function(self)
			print(self)
			local Profiles = self.Keys
			return Profiles
		end

		Functions.GetLoadedProfiles = GetLoadedProfiles

		local HasSession = function(player: Player): boolean
			local key = player.UserId
			if StoreInfo.Keys[key] ~= nil then
				return true
			end
			return false
		end

		Functions.HasSession = HasSession

		--[[
	Stores[storeName] = {
		Store = store,
		Functions = {
			StartSessionAsync = StartSessionAsync,
			WaitForSession = WaitForSession,
			WaitForProfile = WaitForProfile,
			WaitForData = WaitForData,
			GetSession = GetSession,
			GetProfile = GetProfile,
			GetData = GetData,
			HasSession = HasSession,
		},
		Keys = {},
	}
--]]

		return {
			Store = store,
			StartSessionAsync = StartSessionAsync,
			WaitForSession = WaitForSession,
			WaitForProfile = WaitForProfile,
			WaitForData = WaitForData,
			GetSession = GetSession,
			GetProfile = GetProfile,
			GetData = GetData,
			GetLoadedProfiles = GetLoadedProfiles,
			HasSession = HasSession,
			d = "",
		}
	end

	local new = NewStore(storeName, template)
	print(new)

	Stores[storeName] = new
	print(Stores[storeName])

	return new
end

function DataStore.GetStore(storeName: StoreName): StoreInfo?
	IsReady()
	local StoreData = Stores[storeName]
	if not StoreData then
		LogError("[DataStore] Store not found.")
		return
	end
	return StoreData
end
return DataStore
