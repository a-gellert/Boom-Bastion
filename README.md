# Bastion Blast

2D turn-based castle demolition for the browser. Pull back a slingshot, launch a fighter
through floating `x2` / `x3` gates, carve holes in segmented walls and drop whole floors on
the enemy garrison.

**Engine:** Defold 1.14 (Lua, no Box2D, no external game dependencies)
**Target:** HTML5 / WebGL — Poki, CrazyGames, Yandex Games; desktop and mobile web
**Design resolution:** 1280×720, landscape
**Languages:** EN, RU, PT, TR

## Status

| Milestone | What it is | State |
| --- | --- | --- |
| M0 | Cleanup + buildable skeleton | done |
| M1 | Procedural art pack + look-dev frame | done |
| M2 | Core battle: segmented walls, Pull & Release, gates, collapse | done |
| M3 | 8 units, 6 gates, AI, biomes, levels 1–10 | done |
| **M4** | 30 levels / 6 biomes, perks, gold + meta, Hotseat 2P | done |
| M5 | Sound settings, stars, Poki hooks, icon, 60 FPS, 4.55 MB release | done |
| **M6** | Endless mode, final balance, store pack, 2.56 MB zip | done |
| M7 | Live updates and extra content | planned |

## Features

- **30 battles across 6 biomes** (meadow, dunes, frost, caldera, sky, night), bosses every 5th.
- **Pull & Release** aiming with a rubber-band preview, dotted arc, power curve and aim zoom.
- **Segmented walls**: bricks crack, break off, lose their path to the foundation and fall;
  floors with too few bricks drop on the floor below and crush it.
- **Physics juice**: chunks with spin and bounces, shockwave rings, hit flashes, screen shake,
  hit stop, comic words, slow motion on the final kill.
- **8 fighters** with different projectiles, splash, pierce and ranges; 4 in the squad.
- **6 gate types**: x2, x3, fire, giant, pierce, speed — sometimes two per level.
- **Hazards**: central hill, hanging explosive barrels, crosswind.
- **12 roguelite perks** picked from three cards after each victory.
- **Gold + meta upgrades** (wall fortify, power, vitality) saved through `sys.save` / IndexedDB.
- **1–3 stars** per level from turn count, persisted with the save; stars add gold.
- **Endless mode** after the campaign: six biomes cycle, squads rotate, bosses every fifth wave,
  perks carry across waves and the best wave is saved.
- **Local Hotseat 2P** on one screen, with the same pull controls for both castles.
- **Sound settings** in the pause panel (SFX and music), persisted with the save.
- **Poki hooks**: gameplay start/stop, happy time, ad breaks every third win, mute during ads;
  the bridge is a no-op outside Poki hosts.
- **EN / RU / PT / TR**, 0 external dependencies, one atlas, 4.55 MB release build.

## Build and run

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1              # debug, 5.02 MB
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Variant release  # 4.55 MB
powershell -ExecutionPolicy Bypass -File tools/package.ps1            # dist/BastionBlast-web.zip (2.56 MB)
powershell -ExecutionPolicy Bypass -File tools/serve.ps1
```

Store pack: `powershell -File tools/gen_store.ps1` regenerates `store/` from the headless
captures — icon, seven 1280×720 screenshots, 1280×720 and 1920×1080 key art.

Open <http://127.0.0.1:8080/>.

Every build runs `tools/patch_bundle.js`: it copies the app icon and `poki.js`, then injects
favicon, theme, Open Graph tags and the Poki SDK loader into Defold's `index.html`.

Headless smoke test (loads the build in Edge/Chrome, counts Lua/JS errors, saves screenshots):

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke.ps1 -Steps "wait:6;shot:boot;fps:2000"
powershell -ExecutionPolicy Bypass -File tools/smoke.ps1 -Poki -Steps "wait:4;key:F7;wait:1;shot:ad"
```

Art is generated: `node tools/gen_sprites.js` writes the PNGs, the 512×512 `icon.png`,
`main/assets/game.atlas`, `lua_modules/art_sizes.lua` and a contact sheet at `captures/art_sheet.png`.
Build output is `bundle/web`, captures go to `captures/` — neither is committed.

## Controls

| Action | Input |
| --- | --- |
| Aim / fire | Press anywhere, pull back, release |
| Cancel shot | Right click or return into the dead zone |
| Select unit | click a unit button or `1`–`4` |
| Pause / meta / sound | `Esc`, then META or the SFX / MUSIC toggles |
| Endless | the ENDLESS button on the campaign-complete screen |
| Hotseat 2P | the `2P` button (restarts the current level in 2-player mode) |
| Debug (debug builds) | `5` endless, `F6` lose, `F7` ad, `F8` next level/next wave, `F9` blast, `F10` win, `H` hide HUD |

## Layout

```text
game.project                 no dependencies; 1280x720
main/
  main.collection            main + HUD + audio
  main.script                orchestrator and input routing
  game.render_script         world pass (orthographic) + GUI pass
  entities/sprite/           one generic scriptless sprite for everything
  assets/                    one atlas, fonts (Rubik, OFL), trimmed SFX
gui/hud/                     HUD, perks, meta, result created in code
lua_modules/
  battle.lua                 battle state machine, spawning, damage, juice
  castle.lua                 rooms, bricks, BFS support and collapse
  segmented_wall.lua         brick HP, damage states, blast carving
  ballistics.lua  ai.lua     flight, preview, bot solutions
  units_db.lua  levels_db.lua  biomes_db.lua  perks_db.lua
  progress.lua               gold, meta, stars, best wave, settings, sys.save
  poki.lua                   Poki SDK bridge (no-op off Poki)
  levels_db.lua              thirty campaign levels + endless generator
  constants.lua  camera_controller.lua  i18n.lua  audio.lua
input/game.input_binding     touch, Esc, units 1-4, debug keys
tools/                       build / serve / smoke / procedural art
  patch_bundle.js            icon, favicon, meta tags, Poki SDK loader
  web/poki.js                browser-side Poki bridge with a headless mock
  gen_store.ps1               store screenshots + key art
  package.ps1                release build + dist/BastionBlast-web.zip
store/                       icon, screenshots, 720p/1080p key art
references/                  target art sheets (not shipped)
```

## Rules for contributors

- Game first: no essays, no test suites for their own sake. Short decision records only.
- Every milestone ends with a working build, a screenshot and a commit to `main`.
- No new dependencies without an explicit decision: the target is a 3–5 MB web build.
- No `update()` scripts on bricks, projectiles or debris — one controller drives them.
