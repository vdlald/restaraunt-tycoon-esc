# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Roblox restaurant tycoon prototype built with Rojo. It uses an ECS architecture via Jecs, React for UI, ByteNet for networking, and ProfileStore for player data persistence.

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

Systems are ticked manually in a fixed order in `src/server/init.server.luau`. `AbstractSystem` (`src/server/Systems/AbstractSystem.luau`) provides a thin base class and a `QueryExt` helper for iterating Jecs queries safely.

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

## Tests

TestEZ is configured via `.luaurc` and `testez.yml`, but there is no project-specific test runner script yet. Tests should be placed under a `tests/` directory and excluded from Selene linting.
