# DoomFist AIGC Art Direction and Production Workflow

## 1. Project constraints

- Engine: Godot 4.6, 2D mobile renderer.
- Native viewport: 480 x 270, displayed at 3x scale.
- Game type: side-view action platformer.
- Current player collision: 20 x 40 pixels; placeholder visual is about 32 x 48 pixels.
- Implemented gameplay states include idle, run, jump/fall, uppercut, charged punch,
  punch dash, ground slam, block, control lock, chain capture, slow and silence.
- Current gameplay objects include platforms, checkpoint bell, breakable wall, spikes,
  energy orb, chain trap, projectile emitter, sleep dart, javelin and flashbang.
- Most scenes are still graybox placeholders. Art should remain modular and must not be
  baked into full-room images.

## 2. Recommended visual direction

### Style name

**Limited-palette arcade comic with a pixel finish**

### Visual definition

- Strong, readable silhouettes with thick dark contour lines.
- Flat cel-shaded color areas with two shadow levels and one restrained highlight.
- Chunky geometric armor, simplified anatomy and very limited surface texture.
- Warm gold, dark graphite, deep brown and restrained red for the hero.
- Cool cyan/blue for defensive and chain effects; orange/yellow for punch energy.
- Environments use desaturated stone, industrial metal and warm sand tones so the
  character remains the highest-contrast object.
- Final assets are reduced to the game resolution with nearest-neighbor scaling and a
  controlled palette. The source images do not need to be literal pixel art.

### Why this is the safest Image 2 direction

- Flat shapes and bold contours are easier to reproduce consistently than painterly,
  photorealistic or highly textured art.
- Simplified materials reduce drift in the large mechanical fist.
- A limited palette makes separately generated assets look related after color
  normalization.
- Large silhouettes survive the 480 x 270 viewport and remain readable during fast
  movement.
- The pixel finish hides small generation inconsistencies without relying on Image 2 to
  place every pixel correctly.

### Styles to avoid

- Frame-by-frame, model-generated, pixel-perfect animation.
- Photorealism or realistic 3D rendering.
- Painterly fantasy with soft edges and complex lighting.
- Highly detailed anime rendering with thin line work.
- Full-room background illustrations containing gameplay platforms.
- Baked text, UI labels, cast shadows or floor shadows inside transparent sprites.

## 3. Character production specification

The files under `assets/temp/` are concept references, not production sprites.
`011.jpg` is the stronger structural reference because it contains multiple views.
`assets/temp/aigc/正视图.png` is useful for palette and front-facing details, but it
should not become the direct in-game sprite.

Before public or commercial release, redesign the character enough to avoid depending
on another game's protected character design. Preserve the gameplay fantasy of an
asymmetric heavy gauntlet, not the exact costume, facial marks, armor layout or color
placement.

### Master character sheet

Create one approved master sheet before any animation:

- Front, back and strict side orthographic views.
- Neutral standing pose.
- Identical body proportions and armor parts in every view.
- Separate close-up of the mechanical fist.
- Flat neutral lighting.
- No perspective exaggeration.
- No background other than a removable chroma-key color.

### In-game dimensions

- Authoring canvas: 1024 x 1024 per master pose.
- Final sprite cell: 96 x 96 pixels.
- Visible standing height: about 64-72 pixels.
- Feet anchor: fixed at `(48, 82)` in every 96 x 96 frame.
- Facing direction: author only the right-facing version and flip it in Godot.
- Keep the mechanical fist inside the cell except for attack anticipation or impact
  frames that intentionally use a larger effect layer.

### Recommended animation method

Do not ask Image 2 to generate every animation frame independently.

Use a hybrid AIGC cutout workflow:

1. Generate and approve one strict side-view master.
2. Use image edits, not fresh generations, to create a small number of key poses.
3. Generate isolated body parts from the master: head, torso, upper/lower normal arm,
   upper/lower legs and mechanical fist sections.
4. Rig the parts with `Skeleton2D` or animate them with `AnimationPlayer`.
5. Use squash, stretch, rotation, trails, particles and screen shake in Godot.
6. Reserve sprite swaps for silhouettes that cannot be achieved by the rig, such as
   slam impact or full punch extension.

Suggested pose budget:

| State | AIGC key poses | Runtime treatment |
| --- | ---: | --- |
| Idle | 1 | breathing scale and slight torso motion |
| Run | 3 | rig interpolation and foot timing |
| Jump | 1 | rig pose |
| Fall | 1 | rig pose |
| Uppercut | 3 | anticipation, strike, recovery |
| Punch charge | 2 | charge interpolation plus glow |
| Punch dash | 2 | launch and full extension plus trail |
| Slam | 3 | dive, impact, recovery |
| Block | 1 | rig pose plus shield effect |
| Chained/locked | 1 each | rig tilt and status effect |

## 4. Environment and asset rules

### Modular environment kit

Generate an environment kit, not finished level screenshots:

- 32 x 32 base tiles.
- 32 x 16 and 64 x 32 platform caps.
- Left, center and right platform pieces.
- Wall, floor, corner, inner-corner and damaged variants.
- Foreground debris as separate sprites.
- Midground architecture in repeatable 240 x 135 chunks.
- Background skyline in 480 x 270 layers with no gameplay collision implied.

Use three visual depth bands:

1. Gameplay layer: darkest contour and clearest edges.
2. Midground: lower contrast and fewer details.
3. Background: lowest contrast, cooler values and no hard black outlines.

### Gameplay readability

- Hazard red/orange is reserved for danger and warnings.
- Cyan is reserved for block, chain and defensive technology.
- Yellow/gold pickups must not merge with the hero's fist; use a bright halo or a
  different silhouette.
- Breakable walls require a unique crack pattern and lighter edge.
- Platforms need a continuous, high-contrast top edge.
- Projectile silhouettes must remain recognizable at 16-24 pixels long.

### UI

- Generate only frames, panels, icons and decorative motifs.
- Render all labels, numbers and button prompts with Godot fonts.
- Never ask Image 2 to generate final UI text.
- Keep HUD shapes rectangular and modular so nine-patch scaling is possible.

## 5. Asset inventory and priority

### Milestone A: visual proof

1. Character master turnaround.
2. Right-facing side-view player master.
3. Idle, run, jump, punch dash and slam key poses.
4. One platform tile kit.
5. One background set with three depth layers.
6. Punch, block and slam VFX.
7. Replace art only in `Room_03_Uppercut.tscn` for the first vertical slice.

### Milestone B: gameplay objects

1. Checkpoint bell.
2. Breakable wall.
3. Spike and kill-zone visual language.
4. Chain trap and chain head.
5. Sleep dart, javelin and flashbang.
6. Projectile emitter variants.
7. Energy orb and ability refresh effects.

### Milestone C: presentation

1. HUD frame and skill icons.
2. Tutorial button icons.
3. Title screen and logo treatment.
4. Room transition card.
5. Hit, sleep, slow, silence and checkpoint VFX.

## 6. Image 2 production workflow

### Stage 1: lock the style bible

Create a single style board containing:

- Approved hero side view.
- 12-20 color palette.
- Example platform, wall, prop, projectile, VFX and HUD panel.
- Line thickness reference.
- Shadow and highlight rules.
- Examples of forbidden detail density and forbidden soft rendering.

Do not start batch production until this board is accepted.

### Stage 2: create canonical references

- Give every recurring subject a canonical reference image.
- Reuse the canonical image in every edit request.
- For the player, make edits from the approved side view instead of generating a new
  character from text.
- Change only one pose or asset property per iteration.
- Never depend on a random seed as the identity-control method.

### Stage 3: generate on chroma key

Use a flat `#00ff00` background for opaque sprites. If the subject contains important
green areas, use `#ff00ff`.

Required prompt language:

> Perfectly flat solid chroma-key background. No shadows, gradients, texture,
> reflections or floor plane. Keep the subject separated from the background with
> crisp edges and generous padding. Do not use the key color in the subject.

Remove the key locally, then validate:

- Alpha channel exists.
- All corners are fully transparent.
- No green or magenta fringe remains.
- No disconnected debris is accidentally retained.
- The feet and animation anchor remain stable.

### Stage 4: normalize

Every accepted asset passes through the same deterministic post-process:

1. Crop to the specified canvas without changing the anchor.
2. Reduce to the target size using a fixed resizing recipe.
3. Quantize to the approved palette.
4. Apply nearest-neighbor scaling only.
5. Check outlines at 1x native resolution.
6. Export PNG with alpha.
7. Import into Godot with filtering disabled.

### Stage 5: integration test

Test art in motion, not only in an image viewer:

- Character is readable against all three background layers.
- Fist direction and hit timing match collision.
- Foot position does not slide between poses.
- No sprite exceeds the camera-safe area unexpectedly.
- VFX communicate startup, active and recovery timing.
- Hazards remain clear during punch trails and screen flashes.

### Stage 6: controlled batch production

Produce one asset family at a time:

1. Generate low-cost drafts.
2. Select one composition.
3. Edit the selected image to match the canonical reference.
4. Produce final quality only after shape approval.
5. Normalize and integrate immediately.
6. Record the final prompt, reference images and rejection reason.

Do not generate every project asset first and postpone integration. That allows style,
scale and anchor errors to spread across the whole asset library.

## 7. Prompt templates

### Character key-pose edit

```text
Use case: identity-preserve
Asset type: side-view 2D action-platformer character key pose
Primary request: change only the pose to <POSE>; preserve the exact character identity
Input images: Image 1 is the canonical side-view character reference
Subject: muscular original sci-fi fighter with one oversized mechanical gauntlet
Style/medium: limited-palette arcade comic, bold dark contour, flat cel shading,
chunky readable shapes, designed for a pixel-finished 480 x 270 game
Composition/framing: strict orthographic side view, full body, facing right, feet on
one fixed horizontal baseline, centered with generous padding
Lighting/mood: neutral flat studio lighting
Constraints: preserve body proportions, face, gauntlet construction, costume pieces,
palette and line thickness; keep the entire silhouette visible; no perspective change
Avoid: extra limbs, changed armor, changed hand count, foreshortened camera, motion
blur, floor, cast shadow, text, watermark, soft painterly edges
Background: perfectly flat solid #00ff00 chroma-key background
```

### Modular platform kit

```text
Use case: stylized-concept
Asset type: modular side-view platform tile kit
Primary request: a clean orthographic kit of separate platform and wall modules
Style/medium: limited-palette arcade comic with chunky geometry, bold readable edges
Composition/framing: isolated modules arranged in a grid; front-facing orthographic
Lighting/mood: consistent top-left light, restrained two-step cel shading
Color palette: desaturated sandstone, dark graphite metal, small muted gold accents
Constraints: straight tile boundaries; no perspective; no characters; no baked text;
no cast shadows; each module fully separated
Avoid: full level layout, isometric view, soft painting, dense microtexture, vines
crossing tile boundaries, watermark
Background: perfectly flat solid #00ff00 chroma-key background
```

### VFX sprite sheet

```text
Use case: stylized-concept
Asset type: 2D action-game VFX key frames
Primary request: <EFFECT> shown as six clearly separated animation key frames
Style/medium: graphic arcade-comic energy shapes, hard edges, limited colors
Composition/framing: six equal cells in one horizontal row, centered in each cell,
consistent scale and anchor
Color palette: <APPROVED EFFECT COLORS>
Constraints: no character, no environment, no text, no frame borders, no overlap
Avoid: smoke realism, soft photographic glow, lens flare, watermark
Background: perfectly flat solid #00ff00 chroma-key background
```

## 8. Directory and naming convention

```text
assets/
  art_bible/
    references/
    palettes/
  source_aigc/
    player/
    environment/
    props/
    projectiles/
    vfx/
    ui/
  sprites/
    player/
    environment/
    props/
    projectiles/
    vfx/
    ui/
```

File format:

```text
<family>_<asset>_<view-or-state>_<variant>_vNN.png
```

Examples:

```text
player_hero_side_idle_a_v01.png
player_hero_side_punch_dash_a_v03.png
env_ruins_platform_center_a_v02.png
prop_chain_trap_idle_a_v01.png
vfx_punch_impact_gold_a_v04.png
ui_skill_uppercut_icon_a_v02.png
```

Keep raw generations under `assets/source_aigc/`. Only normalized, game-ready files
belong under `assets/sprites/`.

## 9. Acceptance checklist

An asset is accepted only when all applicable checks pass:

- It matches the approved style board at native 1x resolution.
- Silhouette is readable without internal color.
- Scale and anchor match the asset specification.
- Character identity and mechanical fist construction are unchanged.
- Palette is within the approved range.
- No accidental text, signature or watermark is present.
- Alpha edges are clean.
- No cast shadow or floor plane is baked into movable sprites.
- Tile boundaries and repeat points are usable.
- The asset works in the target Godot scene.
- Prompt, references, version and rejection notes are recorded.

