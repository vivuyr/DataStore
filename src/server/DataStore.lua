local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreTypes = require(ServerScriptService.Server.DataStoreTypes)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

export type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

export type Profile<T> = {
	Data: T & JSONAcceptable,
	LastSavedData: T & JSONAcceptable,
	FirstSessionTime: number,
	SessionLoadCount: number,
	Session: { PlaceId: number, JobId: string }?,
	RobloxMetaData: JSONAcceptable,
	UserIds: { number },
	KeyInfo: DataStoreKeyInfo,

	OnSave: {
		Connect: (self: any, listener: () -> ()) -> {
			Disconnect: (self: any) -> (),
		},
	},

	OnLastSave: {
		Connect: (
			self: any,
			listener: (reason: "Manual" | "External" | "Shutdown") -> ()
		) -> {
			Disconnect: (self: any) -> (),
		},
	},

	OnSessionEnd: {
		Connect: (self: any, listener: () -> ()) -> {
			Disconnect: (self: any) -> (),
		},
	},

	OnAfterSave: {
		Connect: (
			self: any,
			listener: (last_saved_data: T & JSONAcceptable) -> ()
		) -> {
			Disconnect: (self: any) -> (),
		},
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

export type VersionQuery<T> = {
	NextAsync: (self: any) -> Profile<T>?,
}

export type ProfileStoreStandard<T> = {
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

export type ProfileStore<T> = ProfileStoreStandard<T> & {
	Mock: ProfileStoreStandard<T>,
}

export type SessionParams = {
	Steal: boolean?,
}

export type Priority = "Low" | "Normal" | "High"

export type ProfileSession<T> = {
	Profile: Profile<T>,
	Save: (self: SessionImplementation<T>, priority: Priority) -> boolean?,
	EndSession: (self: SessionImplementation<T>) -> (),
}

export type DataStoreDefinition<T> = {
	Store: ProfileStore<T>,

	StartSessionAsync: (self: StoreImplementation<T>, player: Player, params: SessionParams?) -> ProfileSession<T>?,

	WaitForSession: (self: StoreImplementation<T>, player: Player) -> ProfileSession<T>?,

	WaitForProfile: (self: StoreImplementation<T>, player: Player) -> Profile<T>?,

	WaitForData: (self: StoreImplementation<T>, player: Player) -> (T & JSONAcceptable)?,

	GetSession: (self: StoreImplementation<T>, player: Player) -> ProfileSession<T>?,

	GetProfile: (self: StoreImplementation<T>, player: Player) -> Profile<T>?,

	GetData: (self: StoreImplementation<T>, player: Player) -> (T & JSONAcceptable)?,

	GetLoadedProfiles: (self: StoreImplementation<T>) -> { [number]: SessionInfo<T> },

	HasSession: (self: StoreImplementation<T>, player: Player) -> boolean,

	SaveAll: (self: StoreImplementation<T>) -> boolean?,
}

export type StartableStore = {
	HasSession: (self: StoreImplementation<any>, player: Player) -> boolean,

	StartSessionAsync: (self: StoreImplementation<any>, player: Player, params: SessionParams?) -> unknown,
}

export type StartConfiguration = {
	Store: StartableStore,
	Params: SessionParams?,
}

export type StoreName = DataStoreTypes.StoreName | string

export type DataStoreState = "NotReady" | "Ready"

export type SessionInfo<T> = {
	Cooldowns: {
		Save: number?,
	},
	Session: ProfileSession<T>,
}

export type StoreInfo<T> = {
	Store: DataStoreDefinition<T>?,
	Keys: { [number]: SessionInfo<T> },

	Cooldowns: {
		SaveAllCooldown: number?,
	},
}

export type Store = {
	[StoreName]: StoreInfo<any>,
}

type StoreImplementation<T> = {
	Store: ProfileStore<T>,
}

type SessionImplementation<T> = {
	Profile: Profile<T>,
	StoreName: StoreName,
}

export type NewFunction = <T>(storeName: StoreName, template: T & JSONAcceptable) -> DataStoreDefinition<T>

export type Data = {
	ProfileStore: typeof(ProfileStore),
	DataStoreState: DataStoreState,
	Settings: {
		Logging: {
			All: boolean,
			Important: boolean,
		},
		KickIfSessionLost: boolean,
		ShutdownIfConnectionFails: boolean,
		SessionLostMessage: string,
		WaitTimeout: number?,
		CriticalToggleCallback: (() -> any)?,
	},
	Start: (stores: { StartConfiguration }) -> (),
	New: NewFunction,
	EndPlayerSessions: (player: Player) -> (),
	EndAllSessions: () -> (),
	GetStore: (storeName: StoreName) -> DataStoreDefinition<any>?,
}

type ErasedStoreInfo = {
	Store: DataStoreDefinition<any>?,
	Keys: { [number]: SessionInfo<any> },
	Cooldowns: {
		SaveAllCooldown: number?,
	},
}

local Stores: { [StoreName]: ErasedStoreInfo } = {}

local Store: any = {}

Store.__index = Store

local DataStore: Data = {} :: any
DataStore["ProfileStore"] = ProfileStore
DataStore["DataStoreState"] = "NotReady"
DataStore["Settings"] = {
	Logging = {
		All = false,
		Important = true,
	},
	KickIfSessionLost = true,
	ShutdownIfConnectionFails = true,
	SessionLostMessage = "Your data session has ended. Please rejoin.",
	WaitTimeout = 10,
	CriticalToggleCallback = nil,
}

local STARTED: boolean = false

local function LogError(text: string, important: boolean?)
	local logging = DataStore.Settings.Logging
	if important and logging.Important or logging.All then
		warn(text)
	end
end

local function Shutdown()
	if DataStore.Settings.ShutdownIfConnectionFails then
		local text = "Unable to connect to DataStore. Please try again later."
		Players.PlayerAdded:Connect(function(player)
			player:Kick(text)
		end)
		for _, player in Players:GetPlayers() do
			player:Kick(text)
		end
	end
end

local function IsActive<T>(profile: Profile<T>)
	if profile:IsActive() then
		return true
	end

	LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
	return false
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
			LogError("[DataStore] Unable to connect to DataStore", true)
			Shutdown()
			error("[DataStore] Unable to connect to DataStore")
		end
	end
	DataStore.DataStoreState = "Ready"
end

-- Connections

ProfileStore.OnError:Connect(function(error_message, store_name, profile_key)
	LogError(`DataStore error (Store:{store_name};Key:{profile_key}): {error_message}`, true)
end)

ProfileStore.OnCriticalToggle:Connect(function(is_critical)
	if is_critical == true then
		if DataStore.Settings.CriticalToggleCallback then
			LogError(`ProfileStore entered critical state`, true)
			local success, result = pcall(DataStore.Settings.CriticalToggleCallback)
			if not success then
				LogError(("[DataStore] Failed to execute CriticalToggle callback: \n%s"):format(result), true)
			end
		end
	else
		LogError(`ProfileStore critical state is over`, true)
	end
end)

-----------------------------------------------------------------------

function DataStore.Start(stores: { StartConfiguration }): ()
	if STARTED then
		LogError("[DataStore] DataStore cannot be started several times")
		return
	end
	IsReady()
	STARTED = true

	local function StartPlayerSessions(player: Player)
		for _, store in ipairs(stores) do
			if not store.Store:HasSession(player) then
				store.Store:StartSessionAsync(player, store.Params or {})
			end
		end
	end

	Players.PlayerAdded:Connect(StartPlayerSessions)
	for _, player in Players:GetPlayers() do
		StartPlayerSessions(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local key = player.UserId
		for _, store in pairs(Stores) do
			if store.Keys[key] ~= nil then
				store.Keys[key].Session:EndSession()
			end
		end
	end)
end

local function New<T>(storeName: StoreName, template: T & JSONAcceptable): DataStoreDefinition<T>
	if Stores[storeName] then
		error(("[DataStore] A store named '%s' has already been created."):format(storeName))
	end

	local StoreInfo: StoreInfo<T> = { Cooldowns = { SaveAllCooldown = nil }, Keys = {} }
	Stores[storeName] = {
		Store = nil,
		Cooldowns = { SaveAllCooldown = nil },
		Keys = StoreInfo.Keys,
	}

	IsReady()
	local store: ProfileStore<T> = ProfileStore.New(storeName, template :: any)

	--[[
	local function NewStore(): DataStoreDefinition<T>
		IsReady()
		local store: ProfileStore<T> = ProfileStore.New(storeName, template :: any)

		local SaveAllCooldown = nil

		local StartSessionAsync = function(player: Player, params: SessionParams?): ProfileSession<T>?
			local key = player.UserId
			if StoreInfo.Keys[key] then
				LogError(("[DataStore] %s already has an active session."):format(player.Name), true)
				return
			end
			local profile = store:StartSessionAsync(tostring(key), params or {})
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Unable to start session"):format(text), true)
				return profile
			end
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			local EndSession = function(): ()
				if profile:IsActive() then
					profile:EndSession()
				end
				StoreInfo.Keys[key] = nil
			end

			local SaveCooldown = nil

			local Save = function(priority: Priority): boolean?
				if not profile:IsActive() then
					LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
					return
				end
				local now = os.clock()
				if priority ~= "Low" and priority ~= "Normal" and priority ~= "High" then
					priority = "Low"
				end
				if not SaveCooldown or priority == "High" then
					SaveCooldown = now + 60
					profile:Save()
					return true
				end

				local difference = now - SaveCooldown
				if priority == "Normal" and difference > -50 or priority == "Low" and difference > 0 then
					SaveCooldown = now + 60
					profile:Save()
					return true
				end
				LogError(("[DataStore] Time left on Save cooldown: %s"):format(-1 * difference))
				return
			end

			if DataStore.Settings.KickIfSessionLost then
				profile.OnSessionEnd:Connect(function()
					local text = DataStore.Settings.SessionLostMessage
					if type(text) ~= "string" then
						text = "Your data session has ended. Please rejoin."
					end
					player:Kick(text)
				end)
			end

			StoreInfo.Keys[key] = {
				Profile = profile,
				Save = Save,
				EndSession = EndSession,
			}
			return {
				Profile = profile,
				Save = Save,
				EndSession = EndSession,
			}
		end

		local WaitForSession = function(player: Player): ProfileSession<T>?
			local key = player.UserId
			local keys = StoreInfo.Keys
			local session = keys and StoreInfo.Keys[key]
			if not session then
				if DataStore.Settings.WaitTimeout then
					local Security = DataStore.Settings.WaitTimeout
					if type(Security) ~= "number" then
						Security = 0
					end
					if Security < 0 then
						Security *= -1
						LogError("[DataStore] WaitTimeout is negative and is changed to (WaitTimeout) * -1", true)
					end
					if Security == 0 then
						local text = player.Name or "Unknown"
						LogError(("[DataStore] %s Session not found."):format(text))
						return
					elseif Security > 0 then
						for _i = 1, Security do
							task.wait(1)
							if not player.Parent then
								return
							end
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
					if not player.Parent then
						return
					end
					keys = StoreInfo.Keys
					session = keys and StoreInfo.Keys[key]
					if session then
						return session
					end
				end
			end
			return session
		end

		local WaitForProfile = function(player: Player): Profile<T>?
			local session = WaitForSession(player)
			if not session then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] Waiting for %s profile took too long"):format(text))
				return
			end
			return session.Profile
		end

		local WaitForData = function(player: Player): (T & JSONAcceptable)?
			local profile = WaitForProfile(player)
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Data not found."):format(text))
				return
			end
			return profile.Data
		end

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

		local GetProfile = function(player: Player): Profile<T>?
			local session = GetSession(player)
			if not session then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Profile not found."):format(text))
				return
			end
			return session.Profile
		end

		local GetData = function(player: Player): (T & JSONAcceptable)?
			local profile = GetProfile(player)
			if not profile then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Data not found."):format(text))
				return
			end
			return profile.Data
		end

		local GetLoadedProfiles = function(): { [number]: ProfileSession<T> }
			return table.clone(StoreInfo.Keys)
		end

		local HasSession = function(player: Player): boolean
			local key = player.UserId
			if StoreInfo.Keys[key] ~= nil then
				return true
			end
			return false
		end

		local SaveAll = function(): boolean?
			local now = os.clock()
			if not SaveAllCooldown or now >= SaveAllCooldown then
				SaveAllCooldown = os.clock() + 60
				local keys = StoreInfo.Keys
				for _, session in pairs(keys) do
					local profile = session.Profile
					if profile:IsActive() then
						profile:Save()
					else
						LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
					end
				end
				return true
			end
			local left = SaveAllCooldown - now
			LogError(("[DataStore] Time left on SaveAll cooldown: %s"):format(left))
			return
		end

		--[[
	Stores[storeName] = {
		Store = {
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
			SaveAll = SaveAll,
			},
		Keys = {},
	}


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
			SaveAll = SaveAll,
		}
	end

	local new = NewStore()

	StoreInfo.Store = new
	Stores[storeName].Store = new
--]]
	local self: StoreImplementation<T> = setmetatable(
		{
			Store = store,
		} :: any,
		Store
	)

	Stores[storeName].Store = self :: any

	return self :: any
end

DataStore.New = New :: any

local Sessions = {}

Sessions.__index = Sessions

function Store.StartSessionAsync<T>(
	self: StoreImplementation<T>,
	player: Player,
	params: SessionParams?
): ProfileSession<T>?
	local key = player.UserId
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	local store = self.Store
	if StoreInfo.Keys[key] then
		LogError(("[DataStore] %s already has an active session."):format(player.Name), true)
		return
	end
	local profile = store:StartSessionAsync(tostring(key), params or {})
	if not profile then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] %s Unable to start session"):format(text), true)
		return profile
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()

	local session: SessionImplementation<T> = setmetatable({}, Sessions) :: any

	session.Profile = profile
	session.StoreName = storeName
	--[[
	local EndSession = function(): ()
		if profile:IsActive() then
			profile:EndSession()
		end
		StoreInfo.Keys[key] = nil
	end

	local Save = function(priority: Priority): boolean?
		if not profile:IsActive() then
			LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
			return
		end
		local now = os.clock()
		if priority ~= "Low" and priority ~= "Normal" and priority ~= "High" then
			priority = "Low"
		end
		if not SaveCooldown or priority == "High" then
			SaveCooldown = now + 60
			profile:Save()
			return true
		end

		local difference = now - SaveCooldown
		if priority == "Normal" and difference > -50 or priority == "Low" and difference > 0 then
			SaveCooldown = now + 60
			profile:Save()
			return true
		end
		LogError(("[DataStore] Time left on Save cooldown: %s"):format(-1 * difference))
		return
	end
--]]
	if DataStore.Settings.KickIfSessionLost then
		profile.OnSessionEnd:Connect(function()
			local text = DataStore.Settings.SessionLostMessage
			if type(text) ~= "string" then
				text = "Your data session has ended. Please rejoin."
			end
			player:Kick(text)
		end)
	end
	Stores[storeName].Keys[key] = { Cooldowns = { Save = 0 }, Session = session :: any }
	return session :: any
end

function Sessions.Save<T>(self: SessionImplementation<T>, priority: Priority): boolean?
	local profile = self.Profile
	if not profile:IsActive() then
		LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
		return
	end
	local now = os.clock()
	if priority ~= "Low" and priority ~= "Normal" and priority ~= "High" then
		priority = "Low"
	end
	local storeName = self.StoreName
	local StoreInfo = Stores[storeName]
	local key = tonumber(profile.Key)
	local SaveCooldown = StoreInfo.Keys[key].Cooldowns.Save
	if SaveCooldown == 0 or priority == "High" then
		StoreInfo.Keys[key].Cooldowns.Save = now + 60
		profile:Save()
		return true
	end

	local difference = now - SaveCooldown
	if priority == "Normal" and difference > -50 or priority == "Low" and difference > 0 then
		StoreInfo.Keys[key].Cooldowns.Save = now + 60
		profile:Save()
		return true
	end
	LogError(("[DataStore] Time left on Save cooldown: %s"):format(-1 * difference))
	return
end

function Sessions.EndSession<T>(self: SessionImplementation<T>): ()
	local profile = self.Profile
	if profile:IsActive() then
		profile:EndSession()
	end
	local storeName = self.StoreName
	local StoreInfo = Stores[storeName]
	local key = profile.Key
	StoreInfo.Keys[key] = nil
end

function Store.WaitForSession<T>(self: StoreImplementation<T>, player: Player): ProfileSession<T>?
	local key = player.UserId
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	local keys = StoreInfo.Keys
	local sessionInfo = keys and StoreInfo.Keys[key]
	local session = sessionInfo and sessionInfo.Session
	if not session then
		if DataStore.Settings.WaitTimeout then
			local Security = DataStore.Settings.WaitTimeout
			if type(Security) ~= "number" then
				Security = 0
			end
			if Security < 0 then
				Security *= -1
				LogError("[DataStore] WaitTimeout is negative and is changed to (WaitTimeout) * -1", true)
			end
			if Security == 0 then
				local text = player.Name or "Unknown"
				LogError(("[DataStore] %s Session not found."):format(text))
				return
			elseif Security > 0 then
				for _i = 1, Security do
					task.wait(1)
					if not player.Parent then
						return
					end
					keys = StoreInfo.Keys
					sessionInfo = keys and StoreInfo.Keys[key]
					session = sessionInfo and sessionInfo.Session
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
			if not player.Parent then
				return
			end
			keys = StoreInfo.Keys
			sessionInfo = keys and StoreInfo.Keys[key]
			session = sessionInfo and sessionInfo.Session
			if session then
				return session
			end
		end
	end
	return session
end

function Store.WaitForProfile<T>(self: StoreImplementation<T>, player: Player): Profile<T>?
	local session = Store.WaitForSession(self, player)
	if not session then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] Waiting for %s profile took too long"):format(text))
		return
	end
	return session.Profile
end

function Store.WaitForData<T>(self: StoreImplementation<T>, player: Player): (T & JSONAcceptable)?
	local profile = Store.WaitForProfile(self, player)
	if not profile then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] %s Data not found."):format(text))
		return
	end
	return profile.Data
end

function Store.GetSession<T>(self: StoreImplementation<T>, player: Player): ProfileSession<T>?
	local key = player.UserId
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	local keys = StoreInfo.Keys
	local sessionInfo = keys and StoreInfo.Keys[key]
	local session = sessionInfo and sessionInfo.Session
	if not session then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] %s Session not found."):format(text))
		return
	end
	return session
end

function Store.GetProfile<T>(self: StoreImplementation<T>, player: Player): Profile<T>?
	local session = Store.GetSession(self, player)
	if not session then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] %s Profile not found."):format(text))
		return
	end
	return session.Profile
end

function Store.GetData<T>(self: StoreImplementation<T>, player: Player): (T & JSONAcceptable)?
	local profile = Store.GetProfile(self, player)
	if not profile then
		local text = player.Name or "Unknown"
		LogError(("[DataStore] %s Data not found."):format(text))
		return
	end
	return profile.Data
end

function Store.GetLoadedProfiles<T>(self: StoreImplementation<T>): { [number]: SessionInfo<T> }
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	return table.clone(StoreInfo.Keys)
end

function Store.HasSession(self: StoreImplementation<any>, player: Player): boolean
	local key = player.UserId
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	if StoreInfo.Keys[key] ~= nil then
		return true
	end
	return false
end

function Store.SaveAll(self: StoreImplementation<any>): boolean?
	local now = os.clock()
	local storeName = self.Store.Name
	local StoreInfo = Stores[storeName]
	local cooldown = StoreInfo.Cooldowns.SaveAllCooldown
	if not cooldown or now >= cooldown then
		StoreInfo.Cooldowns.SaveAllCooldown = os.clock() + 60
		local keys = StoreInfo.Keys
		for _, sessionInfo in pairs(keys) do
			local session = sessionInfo.Session
			local profile = session.Profile
			if profile:IsActive() then
				profile:Save()
			else
				LogError(("[DataStore] Session (%s) is not active"):format(profile.Key))
			end
		end
		return true
	end
	local left = cooldown - now
	LogError(("[DataStore] Time left on SaveAll cooldown: %s"):format(left))
	return
end

function DataStore.EndPlayerSessions<T>(player: Player): ()
	IsReady()
	local key = player.UserId
	for _, store in pairs(Stores) do
		if store.Keys[key] then
			local sessionInfo = store.Keys[key]
			local profile = sessionInfo.Session
			if IsActive(profile.Profile) then
				profile:EndSession()
			end
		end
	end
end

function DataStore.EndAllSessions<T>(): ()
	IsReady()
	for _, store in pairs(Stores) do
		for _, sessionInfo in pairs(store.Keys) do
			local session = sessionInfo.Session
			if IsActive(session.Profile) then
				session:EndSession()
			end
		end
	end
end

function DataStore.GetStore(storeName: StoreName): DataStoreDefinition<any>?
	IsReady()
	local StoreData = Stores[storeName]
	local store = StoreData and StoreData.Store
	if not store then
		LogError("[DataStore] Store not found.")
		return
	end
	return store
end
return DataStore
