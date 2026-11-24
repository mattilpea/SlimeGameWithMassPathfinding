# Slime Game (Mass Pathfinding)

**⚠️ WORK IN PROGRESS: ACTIVE PROJECT**

A multiplayer Roblox wave-survival game where squads of players fight off hundreds of slimes at once, powered by a custom grid-based **flow field pathfinding** system instead of Roblox's built-in `PathfindingService`.

The main goal of this project was solving one problem: **how do you move 200+ enemies toward multiple players every frame without the server falling over?**

---

# Overview

The game is split into two places:

1. **Lobby (SlimeGame)**: players pick a class, form a party in a queue zone, and get teleported together into a reserved server
2. **Match (Actual_Game)**: the gameplay place where slimes spawn and swarm the players

Core gameplay loop:

```text
Lobby -> Pick Class -> Join Party -> Teleport -> Fight Slimes -> Earn Credits -> Gems -> Unlock Classes
```

---

# Why Not PathfindingService?

`PathfindingService` computes one path per agent. With 200 slimes and 4 players, that means hundreds of path computations that need to be redone every time a player moves.

A **flow field** flips the problem around:

- One field is computed **per target (player)**, not per slime
- Every slime chasing that player just reads the field from the cell it's standing on
- 200 slimes chasing 4 players = **4 field calculations**, not 200 paths

The cost of pathfinding no longer grows with the number of enemies.

---

# Included Systems

## Nav Grid Generation (Baked)

Before the game runs, every map gets a navigation grid baked for it using a physics-based "drop test".

How it works:

- A grid of parts is spawned across the map between two marker points (`NavGridPoints.Start` / `End`)
- Cell size matches each slime type's size, so bigger slimes get a coarser grid
- Any part that spawns **inside** geometry is removed straight away (`GetTouchingParts`)
- The rest are unanchored with low gravity and fall
- Every Heartbeat, each part runs a downward `Blockcast` and anchors itself once it lands on the floor
- Cells that land outside the map's `HighestPoint` / `LowestPoint` range are destroyed and marked as **dead ends**

```lua
local direction = -part.CFrame.UpVector
local hit = CastBlock(part, direction)

if hit and hit.Instance then
	part.Anchored = true
	cell["Casted"] = true
	conn:Disconnect()
end
```

The finished grid is saved into `ServerStorage.Maps.<Map>.NavGrids.<SlimeType>` and copied into the live game, so **none of this runs during a match**. At runtime the grid is rebuilt instantly from the saved parts with `NavGrid.FromFolder`.

Because the cells are dropped onto the real map, the grid follows terrain, ramps, platforms and elevation changes automatically. No navmesh is placed by hand.

---

## Flow Field Pathfinding

Each target gets a cost field generated over the grid:

- Starts from an **arrival zone** (a circle of cells around the target) at cost `0`
- Expands outward across all **8 directions** (including diagonals)
- Blocks movement between cells with a height difference greater than `MAX_STEP_HEIGHT`
- Snaps to the nearest valid cell if the player is standing somewhere unwalkable (mid-air, on a ledge)

```lua
local moveCost = math.abs(dir.X) + math.abs(dir.Y) == 2 and 1.414 or 1
local newCost = currentCost + moveCost

if newCost < costs[nx][nz] then
	costs[nx][nz] = newCost
	table.insert(queue, { x = nx, z = nz })
end
```

Slimes then simply step to whichever neighbouring cell has the **lowest cost** and isn't occupied.

Fields refresh on a timer (`FLOWFIELD_REFRESH_RATE`) rather than every frame, keeping the server cost predictable.

---

## Crowd Control / Cell Occupancy

To stop 200 slimes from stacking into one blob:

- Each cell can only hold **one slime**
- A slime **reserves** its next cell before moving into it
- If the best cell is taken, the slime waits instead of overlapping
- Spawning picks the nearest **free** cell, and if none are left the slime isn't spawned

This makes slimes naturally spread out, queue up and surround players instead of clipping through each other.

---

## Target Balancing

With multiple players, slimes are **split evenly** between them rather than all chasing the closest one.

- Each player gets an equal number of "slots" (`floor(slimes / players)`, remainder handed out one by one)
- Every slime/player pair is sorted by distance
- Pairs are assigned greedily, closest first, until slots are full

```lua
local baseAmount = math.floor(slimeCount / targetCount)
local extra = slimeCount % targetCount
```

This runs every second, so if a player dies or leaves, the swarm redistributes itself across the remaining players.

---

## Slime Director / Managers

The AI is layered so each piece has one job:

| Module | Responsibility |
|---|---|
| `SlimeDirector` | Owns all managers, runs one shared Heartbeat loop |
| `SlimeManager` | One per grid size: spawning, targeting, flow fields, attacks, death |
| `FlowField` | Generates cost fields and picks the next cell |
| `NavGrid` | Grid data, world ↔ cell conversion |
| `SlimeMover` | Smooth lerped movement between cells + facing direction |
| `SlimeAnimator` | Idle / Attack / Hit / Death animation states |
| `SlimeInfo` | Data-driven stats per slime type |

Slime types that share a size share a manager and a grid. Adding a new slime type is just a new entry in `SlimeInfo`:

```lua
["Speedy Slime"] = {
	Name = "Speedy Slime",
	SlimeModel = Slimes.Speedy_Slime,
	AttackDamage = 10,
	Speed = 30,
	...
},
```

Current slime types: Normal, Fire, Ghost, Giant, Giant Demon, Golden and Speedy.

---

## Weapons System

Server-authoritative combat with two weapon types:

- **Melee**: cone-based hit detection in front of the player (range + angle)
- **Projectile**: arcing projectiles that deal AOE damage on impact

Features:

- 4-tier loadout system (`SelectedTier1` to `SelectedTier4`)
- Server-side cooldown validation per weapon
- Server checks the weapon is actually equipped **and** selected before any hit is processed
- Client aim system with PC and mobile support
- Damage routed through a `TakeDamage` BindableEvent on each slime, so weapons never touch AI state directly

---

## Lobby, Parties and Teleporting

- Queue zones detected using **ZonePlus**
- The first player into a zone becomes the **host** and picks the party size (1–4)
- Party expires if the host doesn't start in time
- Countdown, then the whole party is teleported into a **reserved server**
- Teleports wrapped in a retry handler (`SafeTeleport`) to handle flooded/failed teleports

---

## Classes and Data

- Class shop with gem prices and ownership checks done on the server
- Classes are data-driven (`ClassesInfo`), each with 3 abilities
- Player data saved with **ProfileStore** (session locking, `Reconcile`, separate Studio/Live stores)
- Credits earned in a match are converted into gems when the player leaves

---

# Math & Algorithms

### 1. World → Grid Conversion

Converting a world position to a grid cell:

x = floor((pos.X − minX) / cellSize) + 1
z = floor((pos.Z − minZ) / cellSize) + 1

This makes every cell lookup **O(1)**, with no searching.

### 2. Flow Field Costs

Movement cost between neighbours:

* Straight move = 1
* Diagonal move = √2 ≈ 1.414

The field is filled with a queue-based expansion that re-queues a cell whenever a cheaper route to it is found, so each cell ends up holding the shortest walkable distance to the target.

### 3. Arrival Radius

Cells count as "arrived" if they fall inside a circle around the target:

√(dx² + dz²) ≤ radius

This gives slimes a ring to surround the player in, instead of all fighting over one cell.

### 4. Melee Cone Detection

A slime is hit if it's within range and inside the swing angle, using the dot product:

forward · offset.Unit ≥ cos(θ / 2)

Everything is flattened onto the XZ plane, so height doesn't affect the swing.

### 5. Projectile Arc

Projectiles move along a straight line with a sine arc added on top:

position = lerp(origin, impact, α) + (0, sin(απ) · h, 0)

This gives a clean parabola-like arc that always lands exactly on the aimed point.

### 6. Cell Movement

Slimes move between cells using linear interpolation:

travelTime = distance / speed
α += dt / travelTime

This keeps movement smooth and frame-rate independent without using physics or Humanoids.

---

# Performance Design

- **No Humanoids on slimes**: models are moved with `PivotTo` and animated through an `AnimationController`
- **No physics** on slimes during movement
- **Nav grids are baked offline**, so there's zero raycasting during gameplay
- **Pathfinding cost scales with players, not enemies**
- **Single Heartbeat loop** drives every slime through the director
- Flow fields and target reassignment run on **timers**, not every frame

Currently tested with **200 slimes** (100 Fire + 100 Normal) on one map.

---

# Project Structure

```text
SlimeGame/
├── SlimeGame_fixed/                 (Lobby place)
│   └── src/
│       ├── ReplicatedStorage/Modules/
│       │   ├── SafeTeleport
│       │   ├── UiAnimations
│       │   └── Zone (ZonePlus)
│       ├── ServerScriptService/
│       │   ├── QueueServer
│       │   ├── ClassesManager
│       │   ├── Data/
│       │   └── Libraries/ (ProfileStore)
│       └── StarterGui/ (HUD, Classes, Party UI)
│
└── Actual_Game_fixed/               (Match place)
    └── src/
        ├── ServerScriptService/
        │   ├── Scripts/
        │   │   ├── SlimeScript
        │   │   └── WeaponsScript
        │   ├── ServerModules/
        │   │   ├── SlimeModule/
        │   │   │   ├── NavGrid/
        │   │   │   ├── FlowField
        │   │   │   ├── SlimeDirector
        │   │   │   ├── SlimeManager
        │   │   │   ├── SlimeMover
        │   │   │   ├── SlimeAnimator
        │   │   │   └── SlimeInfo
        │   │   └── WeaponsModule/
        │   ├── Data/
        │   └── Testing/
        │       └── NavGridGenerationScript
        └── StarterPlayer/
            └── ClientWeaponsSystem/
```

---

# Adding a New Map

1. Add the map under `ServerStorage.Maps.<MapName>`
2. Place `NavGridPoints.Start` and `NavGridPoints.End` at opposite corners of the playable area
3. Set `HighestPoint` / `LowestPoint` in `NavGridPoints.Configuration`
4. Run `NavGridGenerationScript` in Studio
5. Copy the generated `NavGrids` folder into the live game

---

# Development Stack

* Roblox Studio
* Luau (`--!strict` across the core modules)
* Rojo
* Git + GitHub
* Visual Studio Code

---

# Credits / Libraries

* [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) by loleris: player data
* [ZonePlus](https://github.com/1ForeverHD/ZonePlus) by ForeverHD: lobby queue zones
* UiAnimations: my own UI animation module ([roblox-ui-animations](https://github.com/mattilpea/roblox-ui-animations))

---

# Important Note

This project is still in active development.

Some parts are unfinished or placeholder:

- Class abilities are defined in data but not all of them are implemented yet
- Several weapons don't have tool models yet
- `Trash/` and `oldStuff/` folders hold older versions of the slime AI and weapons, kept for reference

Some scripts reference models, maps and assets that only exist inside the place files and aren't included in this repository.

---

# About This Project

This project started as an experiment to see how many enemies Roblox could handle chasing players at once, and turned into a full game built around that system.

It's the first time I've built a large-scale AI system that focuses on **scaling** rather than just working, and moving from per-agent pathfinding to flow fields was the biggest thing I learned from it.

## Author

Created by mattilpea
Roblox / Discord / Twitter / YouTube: @mattilpea
