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

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%). Format flags (-c, -l, -L, -o, -Z) run raw.
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->