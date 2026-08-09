# Best Practices

## Create stores once

Call `DataStore.New` once for each unique store name during server initialization. Duplicate names raise an error.

## Start once

Call `DataStore.Start` once after all stores are created. Repeated calls are ignored with an important log message.

## Choose waiting or immediate access deliberately

Use `WaitForSession`, `WaitForProfile`, and `WaitForData` when the caller can wait for loading. Use `GetSession`, `GetProfile`, and `GetData` when the caller must not yield and can handle `nil`.

## Keep the session lifecycle explicit

Use `StartSessionAsync` for manual loading and `EndSession` when manually ending an individual session. For manager-wide cleanup, use `DataStore.EndPlayerSessions()` or `DataStore.EndAllSessions()`.

## Save intentionally

`session:Save()` uses priority-specific cooldowns, while `store:SaveAll()` has a 60-second cooldown. Both can return `nil`.

## Use ProfileStore directly when needed

The returned store exposes `Store`, the underlying ProfileStore instance. ProfileStore-specific operations are outside this wrapper's API and should be used only when their package contract is understood.

## Multiple stores

Create separate named stores and pass each one to `DataStore.Start`:

```lua
DataStore.Start({
	{ Store = playerDataStore },
	{ Store = settingsStore, Params = { Steal = false } },
})
```

Use separate templates and accessors for each data domain.
