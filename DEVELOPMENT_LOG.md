# FAF RUN — Credite, Cafele, Colocvii 🎮

## Development Log & Game Summary

---

## 🎯 Game Concept

An endless runner mobile game inspired by **Subway Surfers** and **Temple Run**, set in a fictionalized university campus inspired by **Technical University of Moldova (UTM)** and **FAF** (Faculty of Computers, Informatics and Microelectronics).

### Core Gameplay
- **Three-lane endless runner** with lane switching
- **Collect pistachios** (currency) to earn points and meta-currency
- **Avoid obstacles** - one hit = crash (Subway Surfers style)
- **Revive system** using collected pistachios
- **Year progression** from Year 1 → Year 4 (graduation)
- **Study Streak** multiplier system for combo rewards

---

## 🥜 Pistachio Economy System

### Pistachio Rarities
| Rarity | Color | Points | Meta Currency | Spawn Chance |
|--------|-------|--------|---------------|--------------|
| Common | Green | 10 | 1 | 70% |
| Gold | Gold | 50 | 5 | 25% |
| Rare | Purple | 100 | 10 | 5% |

### Features
- **Neon material** for visibility
- **Magnetic attraction** when player is close (8 stud range)
- **Collection range**: 3.5 studs
- **Floating point animations** on collection
- **Infinite spawning** every 0.87-1.1 seconds based on level

---

## 🔥 Study Streak System

Collect pistachios consecutively to build your Study Streak!

### Streak Multipliers
| Streak Level | Pistachios Needed | Score Multiplier |
|--------------|-------------------|------------------|
| Level 1 | 0-24 | x1.2 |
| Level 2 | 25-49 | x1.5 |
| Level 3 | 50-74 | x2.0 |
| Level 4 | 75-99 | x2.5 |
| Level 5 | 100+ | x3.0 |

### Streak Level Up Effect
- Golden banner notification: "🔥 STUDY STREAK x2! 🔥"
- Non-blocking UI (doesn't interfere with gameplay)

---

## 💀 One-Hit Death & Revive System

### Subway Surfers Style
- **Any obstacle hit = INSTANT CRASH**
- No health bars - clean, simple, logical

### Revive Options
- **Cost**: 50 pistachios per revive
- **Max revives per run**: 2
- **5-second countdown** to decide
- **Clears nearby obstacles** on revive
- **2-second invulnerability** after revive

### Crash Screen
- Shows current score and pistachios collected
- "CONTINUE (50 🥜)" button
- "END RUN" button
- Countdown timer for urgency

---

## 🚧 Obstacle Types

### Person Obstacles (40% spawn chance)
- Bostan, Fistic, Cojuhari, Grosu, Braga, Tronciu
- Can be attacked (have health)
- Chase player when in detection range
- Billboard GUI with character images

### Static Obstacles (30% spawn chance)
- Barrier, Pole, Wall, Spikes, Fence, Crate, Pillar, Bench
- Must be avoided - no attacking
- Various sizes and colors

### Moving Obstacles (30% spawn chance)
- SwingingHammer, SlidingBlock, RotatingBlade, Pendulum, Piston
- Move side-to-side between lanes
- Higher difficulty to avoid

---

## 📊 Year Progression (Levels)

| Year | Distance | Obstacle Interval | Pistachio Interval |
|------|----------|-------------------|-------------------|
| Year 1 | 0m | 2.5s | 1.1s |
| Year 2 | 300m | 2.0s | 1.0s |
| Year 3 | 650m | 1.5s | 0.95s |
| Year 4 | 1000m | 1.2s | 0.87s |

### Difficulty Scaling
- Obstacle spawn rate increases with difficulty multiplier
- Double obstacles only spawn in Year 3+ (20% chance)
- Year meter fills as you collect pistachios

---

## Speed Pad Feature

The game now includes dynamic speed-modifying pads distributed along the running platform:

### Speed Pad Types

**Slow-Down Pads (Red)**
- Color: Red with shiny (Neon) material
- Effect: Reduces player speed to 60% for 3 seconds
- Particles: Red/orange trail effect behind player
- Distribution: Random placement every ~4.5 seconds with 60% spawn chance

**Speed-Up Pads (Green)**
- Color: Green with shiny (Neon) material  
- Effect: Increases player speed to 150% for 3 seconds
- Particles: Green trail effect behind player
- Distribution: Random placement every ~4.5 seconds with 60% spawn chance

### Features

- **Collision Detection**: Pads are automatically collected when the player touches them
- **Visual Feedback**: Pads shine with PointLight glow for visibility
- **Particle Trails**: When under a speed effect, particles spawn behind the character in the pad's color
- **Animation Sync**: Running animation playback speed adjusts to match movement speed
- **Duration**: Each speed modifier effect lasts 3 seconds before returning to normal speed
- **Distance Tracking**: Speed pads are despawned when far behind the player to optimize performance

### Technical Details

- Speed pads are spawned in `SpeedPadsFolder` in the `RunnerWorld`
- Configuration available in `CONFIG.speedPads` with customizable multipliers, colors, and spawn chances
- Speed modifier system uses `speedModifier` variable applied to effective speed calculation
- Particle effects created in real-time using Neon material spheres with tweens

---

## 💎 Power-up System (Final Implementation)

Enhanced power-up system now appears **every 4-5 seconds** with balanced spawn rates:

### Power-up Types

**Shield 🛡️ (Blue)**
- Duration: 5 seconds
- Effect: Blocks 1 collision with expanding sphere visual effect
- Spawn Chance: 25% (3x increase from original)
- HUD Display: "🛡️ SHIELD ACTIVE"

**Double Points ⭐ (Gold)**
- Duration: 8 seconds  
- Effect: 2x score multiplier on all coins collected
- Spawn Chance: 30% (3x increase from original)
- HUD Display: Score text turns GOLD + "⚡ 2x ACTIVE!"

**Magnet Boost 🧲 (Pink)**
- Duration: 6 seconds
- Effect: Auto-collects coins within 16 studs (8 base + 8 boost)
- Spawn Chance: 35% (3x increase from original)
- HUD Display: "🧲 MAGNET BOOST"

### Spawn System Changes
- **Frequency**: Every 3.5 seconds (was 15 seconds)
- **Success Rate**: 80% per spawn window (was 35%)
- **Result**: ~4-5 seconds between power-ups (vs ~42 seconds before)
- **Positioning**: Ground level (GROUND_Y + 4) with natural scatter

### Key Mechanics
- **Shield**: Absorbs first collision, creates visual effect, continues game
- **Multiplier**: Visible in real-time HUD with gold highlighting
- **Magnet**: Pulls coins at distance, auto-collects when within 2 studs (Subway Surfers style)
- **HUD Feedback**: All active effects clearly labeled with "ACTIVE" status

---

## 🛡️ Collision & Protection System

### Shield Mechanics
- **Activation**: Checked before crash detection
- **Visual Effect**: Expanding blue neon sphere on impact
- **One-time Use**: Absorbs single collision, then expires
- **HUD Integration**: Immediately removed from display after blocking hit

### Multiplier System
- **Formula**: `totalMultiplier = streakMultiplier × (doublePointsActive ? 2 : 1)`
- **Display**: Score shows actual multiplier in effect (e.g., "x4.0" with streak+2x)
- **Scope**: Applies to all coins collected during active period

---

## 🎨 Visual Features

### HUD Elements
- 📍 Current Year checkpoint
- ⭐ Score with multiplier display
- 🥜 Pistachios collected (run) | 💰 Total (persistent)
- ❤️ Lives remaining & revive cost
- 🔥 Study Streak progress
- 📚 Year Progress percentage

### Effects
- **Collection animations**: Scale up, fade out, float upward
- **Floating point text**: 3D billboards showing "+points"
- **Damage flash**: Red screen overlay on crash
- **Streak level up**: Golden banner notification
- **Neon pistachios**: Glowing collectibles

---

## 🔧 Technical Implementation

### Game Loop
```
RunService.Heartbeat → Every frame:
  ├── Check game state (paused/alive)
  ├── Update distance traveled
  ├── Check level progression
  ├── Increment timers
  ├── Spawn obstacles (if timer ready)
  ├── Spawn pistachios (if timer ready)
  └── Update active objects (collisions, movement)
```

### Key Systems
- **Timer-based spawning** for infinite content
- **Distance-based collision detection** (4 studs for obstacles, 3.5 for pistachios)
- **Magnetic pistachio attraction** for satisfying collection
- **pcall error protection** to prevent game loop crashes
- **Module-level timers** for persistence across respawns

### Folders Structure
```
workspace/
└── RunnerWorld/
    ├── Obstacles/  (all obstacle models)
    └── Pistachios/ (all pistachio parts)
```

---

## 🐛 Bugs Fixed During Development

1. **Git submodule issues** - Removed nested .git folder
2. **Pistachios too high** - Fixed Y position relative to player
3. **Obstacles too high** - Fixed ground-level spawning
4. **Pistachios stop spawning** - Fixed timer persistence, added error protection
5. **Double collection** - Added "Collected" attribute check
6. **Streak breaks collection** - Wrapped in pcall, fixed streak UI
7. **Health system confusing** - Changed to one-hit death (Subway Surfers style)
8. **Game loop duplicates** - Track and disconnect old connections
9. **CRITICAL (Feb 8): totalMultiplier undefined** - Added global calculation in updateHud()
10. **CRITICAL (Feb 8): Animator access error** - Fixed double FindFirstChild() on animator retrieval
11. **Power-up HUD display** - Fixed integration with HUD update system

### Recent Fixes Applied (February 8, 2026):
- ✅ Fixed undefined `totalMultiplier` variable causing HUD crash
- ✅ Fixed Animator pathfinding error in animation speed sync
- ✅ Verified all power-up systems (Shield, Double Points, Magnet Boost) are working
- ✅ Confirmed all spawning systems active: obstacles, pistachios, speed pads, power-ups
- ✅ All core game features remain 100% functional
- ✅ **CRITICAL (Feb 8 - Rendering)**: Removed `AlwaysOnTop = true` from power-up and speed pad billboards so they render in 3D space with proper depth, appearing naturally among obstacles like pistachios (not as 2D overlays)
- ✅ **CRITICAL (Feb 8 - Activation)**: Added 0.5s spawn delay before proximity activation to prevent items from being collected immediately after spawning
- ✅ **POSITIONING FIX**: Power-ups and speed pads now spawn at ground level (GROUND_Y + 3.5-4) with horizontal scatter, matching pistachio behavior perfectly
- ✅ **SPAWN FREQUENCY (Feb 8 - Final)**: Increased power-up spawn rate to every 3.5s with 80% success (was 15s + 35%)
- ✅ **SPEED PAD ANIMATION**: Removed floating bobbing animation, pads now static on platform with only rotation
- ✅ **MAGNET AUTO-COLLECT**: Coins now auto-collect when magnet pulls them within 2 studs (Subway Surfers style)
- ✅ **HUD MULTIPLIER DISPLAY**: Score text turns gold and shows "2x ACTIVE!" when double points enabled
- ✅ **POWER-UP HUD LABELS**: Displays "SHIELD ACTIVE", "2x POINTS!", "MAGNET BOOST" with clear visual feedback
- ✅ **FUNCTION ORGANIZATION**: Reorganized code to define activation functions before creation functions (fixed undefined globals)

---

## 📁 Project Structure

```
FAFRunner/
├── README.md
├── DEVELOPMENT_LOG.md (this file)
├── Runner/
│   ├── default.project.json
│   ├── README.md
│   ├── Runner.rbxl
│   └── src/
│       ├── client/
│       │   └── init.client.luau  (main game logic)
│       ├── server/
│       │   └── init.server.luau
│       └── shared/
│           └── Hello.luau
```

---

## 🚀 Future Improvements

- [ ] Add character customization
- [ ] Implement power-ups (magnet boost, shield, 2x points)
- [ ] Add sound effects and music
- [ ] Create professor chaser mechanic
- [ ] Add daily challenges/missions
- [ ] Implement leaderboards
- [ ] Add shop for spending meta-currency
- [ ] Create "Year Graduation" celebration screens
- [ ] Add sliding and jumping mechanics
- [ ] Implement save/load system for persistence

---

## 🎮 Controls

| Action | Key/Input |
|--------|-----------|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Attack | Left Click / F / E |

---

## 📅 Development Timeline

**Session Date**: February 5, 2026

### Completed This Session:
1. ✅ Fixed Git repository issues
2. ✅ Implemented pistachio economy with 3 rarities
3. ✅ Created Study Streak multiplier system
4. ✅ Changed to Subway Surfers one-hit death
5. ✅ Added revive system with pistachio cost
6. ✅ Created 3 obstacle types (person, static, moving)
7. ✅ Implemented infinite spawning system
8. ✅ Added collection animations and effects
9. ✅ Fixed numerous spawning and collection bugs
10. ✅ Added comprehensive error protection

---

*Built with ❤️ for FAF students at UTM*
