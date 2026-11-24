# Bastion Blast — store pack

Generated from the real game build, not mockups.

| File | Size | Use |
| --- | --- | --- |
| `icon.png` | 512×512 | store icon / PWA |
| `cover_1920x1080.png` | 1920×1080 | key art, trailer thumbnail |
| `cover_1280x720.png` | 1280×720 | store card, social post |
| `screenshots/01_battle.png` | 1280×720 | first battle |
| `screenshots/02_perks.png` | 1280×720 | perk pick after a win |
| `screenshots/03_frost.png` | 1280×720 | frost biome |
| `screenshots/04_night_boss.png` | 1280×720 | night boss |
| `screenshots/05_hotseat.png` | 1280×720 | Hotseat player 2 turn |
| `screenshots/06_endless_boss.png` | 1280×720 | endless wave 5 boss |
| `screenshots/07_meta.png` | 1280×720 | meta upgrades |

## Regenerate

```powershell
powershell -ExecutionPolicy Bypass -File tools/store_capture.ps1
```

It captures English screenshots at 1280×720, hides the HUD with debug key `H` for the
key-art base, then calls `tools/gen_store.ps1` to copy and compose everything.
All screenshots are in-game, 1280×720, English UI.
