# FAFRunner

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
