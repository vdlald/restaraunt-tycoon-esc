---
name: add-content
description: How to add new interactable content to the restaurant tycoon.
---

Typical steps:

1. Add the model/tool template under `ServerStorage` (category folders already exist: `Furniture`, `Ingredient`, `Dish`, `Items`, `NPC`).
2. If the content is reusable/poolable, create a module under `src/server/Game/<Category>/` that uses the appropriate factory.
3. If it needs custom logic, create a system subclassing `AbstractSystem` and process `PlayerInteractComponent`.
4. Wire the new `System` into the heartbeat order in `src/server/init.server.luau`.
5. If it exposes a new placeholder surface, call `PlaceHolder.Create(surfacePart)` during creation.
6. Add any new network messages to `src/shared/Net.luau`.
