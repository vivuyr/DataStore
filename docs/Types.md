# Types

## `Profile<T>`

The loaded ProfileStore profile. It contains `Data`, metadata, session information, user IDs, save/session signals, and ProfileStore methods such as `IsActive`, `Reconcile`, `EndSession`, `Save`, and `MessageHandler`.

## `ProfileSession<T>`

The library's player session wrapper. It contains `Profile: Profile<T>`, `Save(priority: Priority) -> boolean?`, and `EndSession() -> ()`.

## `DataStoreDefinition<T>`

The object returned by `DataStore.New`. It combines the underlying `Store: ProfileStore<T>` with session, waiting, lookup, status, and save helpers.

## `Priority`

The save priority union: `"Low" | "Normal" | "High"`. Invalid runtime values passed to the unexported save implementation are normalized to `"Low"`.

Profile data must be JSON-compatible according to the implementation: arrays, string-keyed dictionaries, numbers, strings, booleans, or buffers.
