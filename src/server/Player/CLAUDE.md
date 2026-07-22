# Player data

`DataManager` (`src/server/Player/DataManager.luau`) uses ProfileStore with optimistic locking:

- Profile key: `Player_{userId}`.
- Uses `StartSessionAsync` / `EndSession` (current ProfileStore API).
- `MutateData(patchName, player, mutation)` copies data, applies the mutation, increments `Revision`, sets `LastPatchName`, and writes back only if the revision has not changed.
- `DataManager:OnProfileDataChanged(callback)` chains callbacks for data-change events.

The server sends net worth (`CoinsEarned - CoinsSpend`) to the client via `playerDataUpdate`.

## Important Roblox Studio setup

To use DataStores in Studio, enable **Studio → Game Settings → Security → Enable Studio Access to API Services**. `DataManager` uses `ProfileStore.Mock` automatically when running in Studio, but the setting still affects other DataStore usage.
