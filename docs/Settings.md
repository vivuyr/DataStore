# Settings

Settings are mutable through `DataStore.Settings`.

## `Logging.All`

- **Default:** `false`.
- **Behavior:** When `true`, all messages sent through the module's logging helper are warned.
- **Example:** `DataStore.Settings.Logging.All = true`.

## `Logging.Important`

- **Default:** `true`.
- **Behavior:** Controls messages marked important, including connection, session, and ProfileStore error messages. It has no effect on non-important messages unless `Logging.All` is enabled.
- **Example:** `DataStore.Settings.Logging.Important = false`.

## `KickIfSessionLost`

- **Default:** `true`.
- **Behavior:** Connects `Profile.OnSessionEnd` to kick the player with `SessionLostMessage`.
- **Example:** `DataStore.Settings.KickIfSessionLost = true`.
- **Disable when:** Your game has its own session-loss recovery flow and should not immediately remove the player.

## `ShutdownIfConnectionFails`

- **Default:** `true`.
- **Behavior:** When access cannot be obtained after the readiness wait, existing players are kicked and future `PlayerAdded` players are kicked.
- **Recommended usage:** Keep enabled in production unless another server-level outage policy is responsible for handling the failure.

## `SessionLostMessage`

- **Default:** `"Your data session has ended. Please rejoin."`.
- **Behavior:** Message passed to `Player:Kick` after a session ends when `KickIfSessionLost` is enabled.
- **Example:** `DataStore.Settings.SessionLostMessage = "Your session ended. Please rejoin."`.

## `WaitTimeout`

- **Default:** `10` seconds.
- **Behavior:** `WaitForSession` checks once per second for up to this many seconds before returning `nil`.
- **Nil behavior:** With `nil`, the function waits indefinitely until a session appears or the player leaves.
- **Negative values:** Negative values are converted to their positive equivalent. For example, `-10` behaves the same as `10`.
- **Zero:** `0` causes `WaitForSession` to return immediately if no session is available.
- **Time unit:** Seconds.

## `CriticalToggleCallback`

- **Default:** `nil`.
- **Behavior:** Optional callback invoked without arguments when ProfileStore enters its critical state. The callback is not invoked when the critical state ends.
- **Error handling:** Callback errors are caught and reported through the module's important logging path; they do not propagate from the ProfileStore event handler.
- **Example:** `DataStore.Settings.CriticalToggleCallback = function() warn("ProfileStore is critical") end`.
- **Disable when:** You do not need a custom response to ProfileStore entering critical state; leave the setting as `nil`.
