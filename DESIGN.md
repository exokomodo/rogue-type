# Rogue Type — Design Document

## Concept

A horizontal bullet hell roguelite with an arcade soul that descends into Lovecraftian horror as the run progresses. Each run is unique, seeded, and progressively harder — structured around Sectors and Bosses in the style of The Binding of Isaac.

**Elevator pitch:** *Galaga's pick-up-and-play satisfaction meets R-Type's deliberate weapon-attachment depth, with Isaac's build-per-run roguelite loop — starting bright and fun, ending in alien nightmare.*

---

## Tone Arc

The game has a deliberate visual and atmospheric progression within each run:

| Early Sectors | Mid Sectors | Late Sectors |
|---|---|---|
| Bright, colorful, arcade-y | Colors desaturate, enemies warp | Full Lovecraftian alien horror |
| Nubby's Number Factory / Galaga energy | Contra mid-game tension | R-Type biomechanical dread |
| Punchy SFX, upbeat music | Distorted audio, dissonance creeps in | Ambient horror, screaming synths |

The player's **ship itself** should subtly mutate visually as corruption increases — a mechanical signal of how deep into the run they are.

---

## Perspective & Layout

- **Horizontal scrolling** (R-Type style) — chosen for PC + mobile landscape compatibility
- **2.5D Depth Illusion (future):** The rightmost portion of the screen bends slightly as if wrapping around a corner — a shader trick giving the impression of flying around a cylindrical or curved surface in space. Creates a sense of infinite depth and unease without full 3D. *(Footnote: implement as a post-process shader pass; the gameplay area remains 2D, the distortion is purely visual and optional/toggleable.)*

---

## Core Loop

```
RUN START
  └─ Sector 1
      ├─ Wave 1: enemies → scrap drops
      ├─ Wave 2: enemies → scrap drops
      ├─ ...
      ├─ [SHOP] — spend scrap on upgrades
      └─ BOSS → defeat → next sector
  └─ Sector 2 (harder, darker)
  └─ ...
  └─ Final Boss → RUN COMPLETE
RUN END → meta-progression rewards
```

---

## Progression Systems

### In-Run (Roguelite)
- **Scrap** — drops from destroyed enemies; currency for the between-wave shop
- **Modular Upgrades** — weapons, shields, engines, force pods; compound in unexpected ways
- **Ship Corruption** — a passive stat that increases as the run deepens; visual mutation, possible gameplay effects (enemy behavior escalates, bullet patterns get stranger)

### Meta (Persistent)
- **Unlockable Ships** — different starting chassis with unique properties (speed-focused, tank, swarm-summon, etc.)
- **Unlockable Starting Loadouts** — begin a run with a specific item pre-equipped
- **Sector Unlocks** — deeper sectors become accessible as you reach them
- **Bestiary / Lore** — each enemy/boss unlocked in a log; feeds the Lovecraftian world-building

---

## Ship & Mechanics

### The Force Pod (Signature Mechanic — R-Type homage)
A detachable companion pod that:
- Absorbs enemy bullets (converts to energy/scrap)
- Can be launched forward as a powerful projectile, then recalled
- Upgradeable — becomes increasingly alien/corrupted in appearance as the run progresses

### Controls (Horizontal)
- **Move:** WASD / Arrow keys / Left stick / Touch drag
- **Fire:** Space / Z / Right trigger / Tap
- **Launch Force Pod:** X / Left trigger / Two-finger tap
- **Recall Force Pod:** X again (or hold)

---

## Enemy & Boss Design

### Wave Enemies
- Procedurally composed bullet patterns using a **pattern grammar** — each enemy has a set of "verbs" (burst, spiral, aimed, wall) that the seeded RNG assembles per run. Feels hand-designed, never identical.
- Early game: simple, readable patterns (Galaga formations)
- Late game: chaotic, overlapping, tentacle-like (Lovecraftian)

### Bosses
- Each Sector ends with a boss
- Bosses have **phases** — visual design changes between phases (increasingly organic/alien)
- First boss should be completable in ~3 minutes; late bosses can take 10+

---

## Seeding

All runs are seeded. The seed controls:
- Enemy wave compositions
- Boss phase patterns
- Shop inventory
- Scrap drop rates
- Corruption escalation pace

Players can share seeds to replay identical runs.

---

## Visual Style

- **Art direction:** MS Paint-adjacent, flat colors, chunky pixels — intentionally lo-fi in the early game
- **Resolution:** Pixel art at 480×270 scaled up (or similar low-res base)
- **Corruption visual progression:** Shader overlays, color grading, geometry distortion applied in layers as sectors deepen

---

## Audio Direction

- Early: chiptune / arcade bleeps
- Mid: lo-fi synth, tension building
- Late: dark ambient, horror drones, discordant
- Boss fights: dynamic music that escalates with phase transitions

---

## Future / Stretch Goals

- Multiplayer co-op (two ships, shared screen)
- Seeded daily challenge runs (same seed for all players that day)
- 2.5D shader (see Perspective section)
- Switch / console port
- Bestiary with full Lovecraftian lore entries per enemy
