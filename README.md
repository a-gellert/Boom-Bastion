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
| **M0** | Cleanup + buildable skeleton | current |
| M1 | Procedural art pack + look-dev frame | next |
| M2 | Core battle: segmented walls, Pull & Release, gates, collapse | planned |
| M3 | 8 units, 6 gates, AI, biomes, levels 1–10 | planned |
| M4 | Perks, meta progression, hotseat, levels 11–30 | planned |
| M5 | Polish, i18n, Poki hooks, performance | planned |
| M6 | Release bundle + store assets | planned |

The old Worms-like prototype lives in git history (commit `c1d495c`); it was stripped in M0.

## Build and run

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1
powershell -ExecutionPolicy Bypass -File tools/serve.ps1
```

Then open <http://127.0.0.1:8080/>.

Headless smoke test (loads the build in Edge/Chrome, counts Lua/JS errors, saves screenshots):

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke.ps1 -Steps "wait:6;shot:boot"
```

Bob and the JDK come from the installed Defold editor (`C:\Program Files (x86)\Defold`).
Build output is `bundle/web`, captures go to `captures/` — neither is committed.

## Controls (M0)

| Action | Input |
| --- | --- |
| Pause | `Esc` |
| Aim / fire | Pull & Release — arrives in M2 |

## Layout

```text
game.project                 no dependencies; 1280x720
main/
  main.collection            main + scene + HUD + audio
  main.script                orchestrator and input
  game.render_script         world pass (orthographic) + GUI pass
  audio.go                   sound components
  entities/scene/            M0 placeholder silhouettes
  assets/                    one atlas, fonts (Rubik, OFL), trimmed SFX
gui/hud/                     HUD created in code
lua_modules/
  constants.lua              all tuning values
  camera_controller.lua      fixed camera + shake/punch/zoom
  i18n.lua                   EN/RU/PT/TR
  audio.lua                  SFX/music with pitch variation
input/game.input_binding     touch, Esc, unit slots 1-4
tools/                       build / serve / smoke
references/                  target art sheets (not shipped)
```

## Rules for contributors

- Game first: no essays, no test suites for their own sake. Short decision records only.
- Every milestone ends with a working build and a screenshot.
- No new dependencies without an explicit decision: the target is a 3–5 MB web build.
- No `update()` scripts on bricks, projectiles or debris — one controller drives them.
