# Installation

## Wally

The repository includes a `wally.toml` manifest and `wally.lock`. Install the declared packages with Wally from the project directory:

```bash
wally install
```

The checked-in package is ProfileStore (`lm-loleris/profilestore`, version `1.0.3` in the lockfile).

## Required dependencies

DataStore requires:

- Roblox services and Luau runtime.
- ProfileStore, exposed to the server as `ServerPackages.ProfileStore`.

`DataStoreTypes` is optional. It provides additional Luau types that can improve type checking and autocomplete for store names and related configuration. The library can be used without it.

If `DataStoreTypes` is used, it must export a `StoreName` type:

```lua
export type StoreName = "PlayerData"

return {}
```

Add your store names to the union as needed:

```lua
export type StoreName = "PlayerData" | "Inventory" | "Settings"

return {}
```

Rojo and Aftman are project tooling; they are not runtime dependencies of the module.

## Folder structure

```text
ServerPackages/DataStore.lua    -- library module
ServerScriptService/server/DataStoreTypes.lua   -- optional store-name type
ServerPackages/ProfileStore.lua -- package entry point
ServerPackages/_Index/...       -- Wally package contents
```

## Minimal setup

Place `DataStore.lua` under `ServerScriptService`, expose ProfileStore under `ServerScriptService.ServerPackages.ProfileStore`, then require the module from a server script:

```lua
local DataStore = require(game.ServerScriptService.DataStore)

local store = DataStore.New("PlayerData", {
    Coins = 0,
})

DataStore.Start({
    { Store = store },
})
```

The implementation waits for ProfileStore to report `Access` before creating a store or starting the manager.
