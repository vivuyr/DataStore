# Error Handling

## DataStore cannot connect

The module waits up to ten seconds for ProfileStore to report `Access`. If access is still unavailable, it logs an important message, optionally kicks players according to `ShutdownIfConnectionFails`, and raises an error.

## Store already exists

`DataStore.New` raises an error when the requested name already exists.

## Session cannot be created

`StartSessionAsync` logs an important message and returns `nil` when the underlying ProfileStore returns no profile.

## Session is lost

ProfileStore's `OnSessionEnd` signal is observed when `KickIfSessionLost` is enabled. The player is kicked with `SessionLostMessage`.

## `WaitFor...` does not obtain a session

`WaitForSession` returns `nil` after a positive `WaitTimeout`, or when the player leaves while waiting. `WaitForProfile` and `WaitForData` propagate that unavailable result as `nil`.

## Invalid settings

`WaitTimeout < 0` logs a warning but then will be changed to WaitTimeout * -1. `SessionLostMessage` is validated at session-loss time; a non-string value falls back to the default message. Logging settings only control warnings and do not throw errors.

ProfileStore errors and critical-state changes are forwarded to the module's logging helper.
