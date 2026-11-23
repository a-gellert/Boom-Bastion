# Agent Guidelines & Behavior — Bastion Blast

## Bug investigation rules
- Do not perform extensive broad codebase scans on vague bug reports.
- If the bug context or error trace is missing, ask the user for console logs or the entry-point file first before reading multiple unrelated files.
- Restrict file exploration to directly relevant modules only.

## Project facts
- Engine: Defold 1.14, Lua, `shared_state = 1`, design resolution 1280x720.
- No external game dependencies. Do not add any without an explicit decision.
- The old Worms-like prototype was stripped in M0; `git show c1d495c` has it if something is needed.
- Art: `node tools/gen_sprites.js` (procedural PNGs -> main/assets/art, atlas, lua_modules/art_sizes.lua). Never hand-edit generated art.
- Build: `powershell -File tools/build.ps1` -> `bundle/web`.
- Run: `powershell -File tools/serve.ps1` -> http://127.0.0.1:8080/.
- Headless check: `powershell -File tools/smoke.ps1` (Edge/Chrome, counts Lua/JS errors, saves screenshots to `captures/`).
- Bob/JDK live in `C:\Program Files (x86)\Defold`.

## Code map
- `main/main.script` — orchestrator: match state machine, input routing, messages.
- `lua_modules/` — pure rules and data: constants, camera, i18n, audio, castle, segmented_wall, ballistics, ai, units_db, levels_db, biomes_db, battle.
- `main/entities/sprite/` — one generic sprite entity. Bricks, projectiles, debris, gates and units are all scriptless sprites driven by battle.lua.
- `gui/hud/` — HUD nodes are created in code (no hand-edited .gui node trees beyond fonts/textures).
- Everything tuning-related lives in `lua_modules/constants.lua` and `*_db.lua` files.

## Working rules
- One mechanic at a time; each milestone ends with a working build, a screenshot and a commit to `main`.
- Keep the build small (target 3-5 MB) and 60 FPS on budget mobile.
- Never edit `SKILL.md` or `references/`.
- Game first: short docs, no ceremony, no test suites that do not protect a real bug.

