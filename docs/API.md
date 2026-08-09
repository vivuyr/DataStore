# API Reference

All methods below are exposed by the returned DataStore module or by a store returned from `DataStore.New`. A `nil` return means the requested session, profile, or data was unavailable.

## DataStore

### `DataStore.Start(stores)`

Starts the manager once, waits for ProfileStore access, starts each configured store for players, and ends tracked sessions when players leave.

- **Parameters:** `stores: { { Store: DataStoreDefinition<any>, Params: { Steal: boolean? }? } }`.
- **Returns:** nothing.
- **Example:**

```lua
DataStore.Start({ { Store = playerStore, Params = { Steal = false } } })
```

- **Notes:** Repeated calls log an error and do nothing. A connection failure raises an error after kicking players when configured.
- **Nil:** no return value.

### `DataStore.New(storeName, template)`

Creates a named store using `template` as the ProfileStore template.

- **Parameters:** `storeName: string`; `template: T & JSONAcceptable`.
- **Returns:** `DataStoreDefinition<T>`.
- **Example:** `local store = DataStore.New("PlayerData", { Coins = 0 })`.
- **Notes:** The name must be unique. Creating a duplicate raises an error. The module waits for data-store access.
- **Nil:** never returns `nil`; failure raises an error.

### `DataStore.EndPlayerSessions(player)`

Ends all sessions tracked for a player ID.

- **Parameters:** `player: Player`.
- **Returns:** nothing.
- **Example:** `DataStore.EndPlayerSessions(player)`.
- **Notes:** Ends all sessions tracked by the DataStore manager for the specified player.
- **Nil:** no return value.

### `DataStore.EndAllSessions()`

Ends every session in the module's internal registry.

- **Parameters:** none.
- **Returns:** nothing.
- **Example:** `DataStore.EndAllSessions()`.
- **Notes:** Ends every session tracked by the DataStore manager across all stores.
- **Nil:** no return value.

### `DataStore.GetStore(storeName)`

Looks up a store by name.

- **Parameters:** `storeName: string`.
- **Returns:** `DataStoreDefinition<any>?`.
- **Example:** `local store = DataStore.GetStore("PlayerData")`.
- **Notes:** Logs an error and returns `nil` when no store with the given name exists. The returned type is `any` because the name alone cannot recover the original generic type.
- **Nil:** returned when the store is unavailable.

## Store

### `StartSessionAsync(player, params?)`

Starts a ProfileStore session using the player's `UserId` converted to a string key, adds the user ID, and reconciles the profile.

- **Parameters:** `player: Player`; optional `params: { Steal: boolean? }`.
- **Returns:** `ProfileSession<T>?`.
- **Example:** `local session = store.StartSessionAsync(player)`.
- **Notes:** A session-loss connection may kick the player when enabled.
- **Nil:** returned when ProfileStore cannot start the session.

### `WaitForSession(player)`

Waits for a player's session to appear.

- **Parameters:** `player: Player`.
- **Returns:** `ProfileSession<T>?`.
- **Example:** `local session = store.WaitForSession(player)`.
- **Notes:** Uses `Settings.WaitTimeout` first, then continues waiting when the timeout is absent. Stops if the player leaves.
- **Nil:** returned after timeout, when the player leaves, or when no session becomes available.

### `WaitForProfile(player)`

Waits for a session and returns its profile.

- **Parameters:** `player: Player`.
- **Returns:** `Profile<T>?`.
- **Example:** `local profile = store.WaitForProfile(player)`.
- **Notes:** Delegates waiting to `WaitForSession`.
- **Nil:** returned when no session is available.

### `WaitForData(player)`

Waits for a profile and returns its data.

- **Parameters:** `player: Player`.
- **Returns:** `(T & JSONAcceptable)?`.
- **Example:** `local data = store.WaitForData(player)`.
- **Notes:** This is a blocking wait according to the configured wait behavior.
- **Nil:** returned when no profile can be obtained.

### `GetSession(player)`

Returns a loaded session without waiting.

- **Parameters:** `player: Player`.
- **Returns:** `ProfileSession<T>?`.
- **Example:** `local session = store.GetSession(player)`.
- **Notes:** Logs when no session is found.
- **Nil:** returned if the player has no loaded session.

### `GetProfile(player)`

Returns a loaded profile without waiting.

- **Parameters:** `player: Player`.
- **Returns:** `Profile<T>?`.
- **Example:** `local profile = store.GetProfile(player)`.
- **Notes:** Delegates to `GetSession`.
- **Nil:** returned if no session is loaded.

### `GetData(player)`

Returns loaded profile data without waiting.

- **Parameters:** `player: Player`.
- **Returns:** `(T & JSONAcceptable)?`.
- **Example:** `local data = store.GetData(player)`.
- **Notes:** Logs when data is unavailable.
- **Nil:** returned if no profile is loaded.

### `GetLoadedProfiles()`

Returns the store's loaded sessions keyed by numeric `UserId`.

- **Parameters:** none.
- **Returns:** `{ [number]: ProfileSession<T> }`.
- **Example:** `for userId, session in pairs(store.GetLoadedProfiles()) do print(userId) end`.
- **Notes:** The returned table is the live session table.
- **Nil:** never returns `nil`.

### `HasSession(player)`

Checks whether a player has a loaded session.

- **Parameters:** `player: Player`.
- **Returns:** `boolean`.
- **Example:** `if store.HasSession(player) then ... end`.
- **Notes:** It does not wait.
- **Nil:** never returns `nil`.

### `SaveAll()`

Calls `Profile:Save()` for every loaded session when its 60-second cooldown allows it.

- **Parameters:** none.
- **Returns:** `true` when saves are issued; `nil` during cooldown.
- **Example:** `local saved = store.SaveAll()`.
- **Notes:** The cooldown is shared by the store. The underlying ProfileStore save result is not returned.
- **Nil:** returned while the cooldown is active.

## Profile session methods

`session.Save(priority)` accepts `"Low"`, `"Normal"`, or `"High"`. `"High"` saves have no cooldown, `"Normal"` saves have a 10-second per-session cooldown, and `"Low"` saves have a 60-second per-session cooldown. Invalid priority values default to `"Low"`. The function returns `true` when a save is issued and may return `nil` if the cooldown for the selected priority is active.
`session.EndSession()` ends the underlying session and removes it from the store's session table.
