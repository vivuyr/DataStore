# Types

## `Profile<T>`

The loaded ProfileStore profile. It contains `Data`, metadata, session information, user IDs, save/session signals, and ProfileStore methods such as `IsActive`, `Reconcile`, `EndSession`, `Save`, and `MessageHandler`.

## `ProfileSession<T>`

The library's player session wrapper. It contains `Profile: Profile<T>`, `Save(priority: Priority) -> boolean?`, and `EndSession() -> ()`.

`ProfileSession` methods are object methods and must be called with `:`:

```lua
session:Save("Normal")
session:EndSession()
```

## `DataStoreDefinition<T>`

The object returned by `DataStore.New`. It combines the underlying `Store: ProfileStore<T>` with session, waiting, lookup, status, and save helpers.

Store methods are provided through the store object's metatable and must be called with `:`:

```lua
store:StartSessionAsync(player)
store:WaitForSession(player)
store:WaitForProfile(player)
store:WaitForData(player)

store:GetSession(player)
store:GetProfile(player)
store:GetData(player)

store:GetLoadedProfiles()
store:HasSession(player)
store:SaveAll()
```

The `DataStore` module functions themselves are not metatable methods and use `.`:

```lua
DataStore.New("PlayerData", { Coins = 0 })
DataStore.Start({ { Store = store } })
DataStore.GetStore("PlayerData")
```

## `Priority`

The save priority union: `"Low" | "Normal" | "High"`. Invalid runtime values passed to the unexported save implementation are normalized to `"Low"`.

## JSON-compatible profile data

Profile data must be JSON-compatible according to the implementation: arrays, string-keyed dictionaries, numbers, strings, booleans, or buffers.
