# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Roblox restaurant tycoon prototype built with Rojo. It uses an ECS architecture via Jecs, React for UI, ByteNet for networking, and ProfileStore for player data persistence.

## Toolchain

Tools are managed by [Rokit](https://github.com/rojo-rbx/rokit). Install them once with:

```bash
rokit install
```

Key tools (versions are pinned in `rokit.toml`):

- `rojo` — sync code into Roblox Studio and build place files.
- `wally` — package manager.
- `selene` — linter.
- `stylua` — formatter.
- `wally-package-types` — generate Luau type definitions from Wally packages.

## Common commands

Install Wally packages after cloning or after changing `wally.toml`:

```bash
wally install
```

Generate package Luau types (creates types under `Packages/` and `ServerPackages/`):

```bash
wally-package-types --sourcemap sourcemap.json
```

Build the place file from the Rojo project:

```bash
rojo build -o "RestaurantTycoonEcs.rbxlx"
```

Start the live-sync server for Roblox Studio:

```bash
rojo serve
```

Lint the codebase:

```bash
selene .
```

Format the codebase:

```bash
stylua .
```

Run tests with TestEZ (no tests exist yet; `.luaurc` and `testez.yml` configure TestEZ globals):

```bash
# There is no project-specific test runner script yet.
# Tests should be placed under a `tests/` directory and excluded from Selene linting.
```

## Rojo project layout

`default.project.json` maps source directories to Roblox services:

- `src/shared` → `ReplicatedStorage.Shared`
- `src/server` → `ServerScriptService.Server`
- `src/client` → `StarterPlayer.StarterPlayerScripts.Client`
- `Packages/` → `ReplicatedStorage.Packages`
- `ServerPackages/` → `ServerScriptService.Packages`
- `DevPackages/` → `ReplicatedStorage.DevPackages` (TestEZ)

## Architecture

### ECS with Jecs

The server uses a single Jecs world exposed through `src/server/World.luau`. Key concepts:

- **Entity** — a Jecs entity id.
- **Instance** — a Roblox instance, usually cloned from `ServerStorage`.
- `WorldWrapper:RegisterInstance(instance, className)` creates an entity, stores `{ Instance, Class }` on it, and writes the entity id to the instance's `entityId` attribute.
- Components are defined in `World.luau` (core) or in individual game modules (domain-specific).

### Interaction pipeline

Player interactions flow through the ECS each heartbeat:

1. Client detects the closest interactable part (`src/client/init.client.luau`) and sends `entityId + keyCode` via ByteNet.
2. Server validates the request in `src/server/init.server.luau` (allowed key, distance, not pooled, instance alive).
3. On success, server sets `WantsToInteractComponent` on the player entity.
4. `PlayerInteractSystem` converts it to `PlayerInteractComponent` on the target entity.
5. Domain systems (furniture, ingredients, dishes, NPCs) query `PlayerInteractComponent` and react.
6. `PlayerInteractSystem:Clear()` removes all `PlayerInteractComponent`s at the end of the frame.

Allowed interaction keys are `E` and `F` (`src/shared/Consts.luau`).

### Systems

Systems are ticked manually in a fixed order in `src/server/init.server.luau`:

```
PlayerInteractSystem
NPC / Guest
Furniture (Trashcan, FlourBag, MeatSteakFridge)
Ingredients (Flour, Dough, RawPie, RawMeatSteak, ChoppedMeat, MinceMeat)
Dishes (Pie)
PlaceHolder (end phase)
PlayerInteractSystem:Clear()
```

`AbstractSystem` (`src/server/Systems/AbstractSystem.luau`) provides a thin base class and a `QueryExt` helper for iterating Jecs queries safely.

### Placeholders and placing items

`PlaceHolder` (`src/server/Components/PlaceHolder.luau`) lets players put items on surfaces (e.g., kitchen tables). It uses two extra components:

- `Holds` — the placeholder currently has an item welded to it.
- `Placed` — the item is currently placed on a placeholder.

Placeholders are created by calling `PlaceHolder.Create(topPart)` on the part that should act as the surface.

### Factories and object pools

Reusable objects are created through factories backed by `ObjectPool` (`src/server/ObjectPool.luau`):

- `IngredientFactory` — craftable ingredients that morph into another ingredient when used (`HandsMorphFunc`).
- `DishFactory` — dishes created by combining ingredients.
- `IngredientFurnitureFactory` — furniture that dispenses or accepts a specific ingredient.

Each factory module returns `{ Component, Pool, System }`. New ingredients/dishes are added by defining a new module that calls the appropriate factory and then wiring its `System` into the heartbeat in `src/server/init.server.luau`.

### Networking

ByteNet namespace is defined in `src/shared/Net.luau`:

- `playerInteract` — client → server, carries `entityId` and `keyCode`.
- `playerDataUpdate` — server → client, currently syncs `coins`.

Client-side state lives in `src/client/State.luau`; UI components (React) subscribe to `Val` observables.

### Player data

`DataManager` (`src/server/Player/DataManager.luau`) uses ProfileStore with optimistic locking:

- Profile key: `Player_{userId}`.
- Uses `StartSessionAsync` / `EndSession` (current ProfileStore API).
- `MutateData(patchName, player, mutation)` copies data, applies the mutation, increments `Revision`, sets `LastPatchName`, and writes back only if the revision has not changed.
- `DataManager:OnProfileDataChanged(callback)` chains callbacks for data-change events.

The server sends net worth (`CoinsEarned - CoinsSpend`) to the client via `playerDataUpdate`.

## Important Roblox Studio setup

To use DataStores in Studio, enable **Studio → Game Settings → Security → Enable Studio Access to API Services**. `DataManager` uses `ProfileStore.Mock` automatically when running in Studio, but the setting still affects other DataStore usage.

## Adding new interactable content

Typical steps:

1. Add the model/tool template under `ServerStorage` (category folders already exist: `Furniture`, `Ingredient`, `Dish`, `Items`, `NPC`).
2. If the content is reusable/poolable, create a module under `src/server/Game/<Category>/` that uses the appropriate factory.
3. If it needs custom logic, create a system subclassing `AbstractSystem` and process `PlayerInteractComponent`.
4. Wire the new `System` into the heartbeat order in `src/server/init.server.luau`.
5. If it exposes a new placeholder surface, call `PlaceHolder.Create(surfacePart)` during creation.
6. Add any new network messages to `src/shared/Net.luau`.

## Style and linting

- Files use `luau` extension and `--!strict` where applicable.
- `selene.toml` excludes generated package folders and `tests/**`.
- `roblox_manual_fromscale_or_fromoffset` is allowed.
- `stylua` is the source of truth for formatting; run it before committing.
