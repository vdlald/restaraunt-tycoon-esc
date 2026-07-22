# Placeholders and placing items

`PlaceHolder` (`src/server/Components/PlaceHolder.luau`) lets players put items on surfaces (e.g., kitchen tables). It uses two extra components:

- `Holds` — the placeholder currently has an item welded to it.
- `Placed` — the item is currently placed on a placeholder.

Placeholders are created by calling `PlaceHolder.Create(topPart)` on the part that should act as the surface.
