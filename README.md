# Oh no! My Boyfriend is Haunted

A 2D/3D hybrid Godot game featuring physics-based dice rolling from a cup onto a tray.

## Core Mechanics (onmbih-inspired)

- **Roll Dice**: Shake the cup (Roll Dice / Space) to pour dice onto the tray. Settled dice earn **Research** points.
- **Tube Shop**: Spend Research to buy tubes (Common 15, Uncommon 30, Rare 60).
- **Open Tube**: Shake out a tube's contents — dice and voxel character allies spill onto the tray.
- **Allies**: Characters from tubes join your investigation (max 5).

## Project Structure

```
├── scripts/
│   ├── dice_mesh_generator.gd   # Procedural polyhedral mesh generation
│   ├── dice.gd                  # RigidBody3D die with physics
│   ├── tray.gd                  # StaticBody3D tray with walls
│   ├── dice_cup.gd              # Cup that holds and pours dice
│   └── game.gd                  # Main game controller
├── scenes/
│   ├── dice/dice.tscn
│   ├── props/tray.tscn
│   ├── props/dice_cup.tscn
│   └── main/game.tscn           # Main scene (entry point)
└── project.godot
```

## Controls

- **Space / Enter**: Roll dice
- **Tube Shop**: Open shop to buy tubes
- **Open Tube**: Spill contents of your next tube (dice + characters)
- **Reset**: Gather dice back into the cup
- **Escape**: Close shop or reset

## Voxel Characters

Character sprites from the browser game (`onmbih/assets/townsfolk`, `onmbih/assets/misc`) can be converted to 3D voxels (10 pixels deep):

```bash
cd onmbih
python3 scripts/pixel_to_voxel.py --exclude-background
```

Output OBJ meshes are in `assets/voxels/`. Use the `VoxelCharacter` scene (`res://scenes/characters/voxel_character.tscn`) with `character_id` or `voxel_mesh_path` set. Characters can be acquired via dice tubes (buy/unlock) and will spill from opening tubes onto the tray.

## Extending the Game

### Tubes with voxel characters
- Voxel character OBJs live in `assets/voxels/townsfolk/` and `assets/voxels/misc/`
- Use `VoxelCharacter` node with `character_id` (e.g. `"teenBoy01"`) or `voxel_mesh_path`
- Tube contents (dice + characters) defined in `onmbih/js/data/diceTubes.js`

### Dice types
Edit `game.gd` → `dice_types` array to change the mix (e.g. `[4, 6, 8, 10, 12, 20]` for one of each).

### 2D overlay
The `CanvasLayer` in `game.tscn` holds the 2D UI. Add sprites, dialogue, or a character portrait here for the "Oh no! My Boyfriend is Haunted" narrative layer.

## Requirements

- Godot 4.6+
- Jolt Physics (already configured in project)
