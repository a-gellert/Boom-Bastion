"""
Process and package Nano Banana generated weapons and projectiles into Defold assets.
"""

import os
import numpy as np
from PIL import Image

BRAIN_DIR = r"C:\Users\User\.gemini\antigravity\brain\0e7984eb-b807-473d-aa11-f7092552bc85"
WEAPONS_SHEET = os.path.join(BRAIN_DIR, "weapons_spritesheet_1794589449626.jpg")
PROJECTILES_SHEET = os.path.join(BRAIN_DIR, "projectiles_spritesheet_1794589461353.jpg")
DEST_DIR = r"d:\DProjects\Potato-War\main\assets\weapons"
HIRES_DIR = os.path.join(DEST_DIR, "hires")

os.makedirs(DEST_DIR, exist_ok=True)
os.makedirs(HIRES_DIR, exist_ok=True)


def extract_sprite(crop_img, bg_thresh=248, edge_feather=16):
    """
    Smooth anti-aliased cutout from solid white background with de-fringing
    to eliminate halo artifacts on dark outlines.
    """
    arr = np.array(crop_img, dtype=np.float32)
    min_rgb = np.min(arr, axis=2)
    t = (bg_thresh - min_rgb) / float(edge_feather)
    alpha = np.clip(t, 0.0, 1.0)

    # De-fringe: unmultiply white background from edge pixels
    safe_alpha = np.maximum(alpha, 0.01)[:, :, np.newaxis]
    rgb_clean = (arr - (1.0 - safe_alpha) * 255.0) / safe_alpha
    rgb_clean = np.clip(rgb_clean, 0.0, 255.0)

    rgba = np.dstack([rgb_clean, alpha * 255.0]).astype(np.uint8)
    res = Image.fromarray(rgba, mode="RGBA")
    bbox = res.getbbox()
    if bbox:
        res = res.crop(bbox)
    return res


def fit_into_canvas(src_img, target_w, target_h, pad_x=2, pad_y=2):
    avail_w = target_w - pad_x * 2
    avail_h = target_h - pad_y * 2
    scale = min(avail_w / src_img.width, avail_h / src_img.height)
    new_w = max(1, int(round(src_img.width * scale)))
    new_h = max(1, int(round(src_img.height * scale)))

    scaled = src_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    offset_x = (target_w - new_w) // 2
    offset_y = (target_h - new_h) // 2
    canvas.paste(scaled, (offset_x, offset_y), scaled)
    return canvas


def main():
    print(f"Loading master sheets from {BRAIN_DIR}...")
    im1 = Image.open(WEAPONS_SHEET).convert("RGB")
    im2 = Image.open(PROJECTILES_SHEET).convert("RGB")

    weapons_cells = {
        "w_bazooka": (20, 100, 330, 260),
        "w_sniper": (345, 100, 680, 260),
        "w_shotgun": (690, 100, 1015, 260),
        "w_homing": (20, 320, 335, 645),
        "w_grenade": (350, 320, 680, 645),
        "w_dynamite": (690, 320, 1015, 645),
        "w_cluster": (20, 670, 340, 990),
        "w_holy": (350, 670, 680, 990),
        "w_airstrike": (690, 670, 1015, 990),
    }

    projectiles_cells = {
        "p_rocket": (45, 75, 340, 260),
        "p_missile": (380, 75, 690, 260),
        "p_bullet": (690, 75, 1040, 260),
        "p_pellet": (1075, 75, 1330, 260),
        "p_airbomb": (45, 375, 340, 700),
        "p_bomblet": (380, 375, 690, 700),
        "plane": (690, 375, 1040, 700),
        "target": (1075, 375, 1330, 700),
    }

    # Canvas specs for in-game assets (width, height, pad_x, pad_y)
    canvas_specs = {
        "w_bazooka": (124, 56, 2, 2),
        "w_sniper": (140, 54, 2, 2),
        "w_shotgun": (124, 50, 2, 2),
        "w_homing": (124, 96, 2, 2),
        "w_grenade": (44, 56, 2, 2),
        "w_dynamite": (48, 64, 2, 2),
        "w_cluster": (52, 52, 2, 2),
        "w_holy": (52, 64, 2, 2),
        "w_airstrike": (44, 64, 2, 2),
        "p_rocket": (48, 24, 2, 2),
        "p_missile": (48, 24, 2, 2),
        "p_bullet": (28, 12, 1, 1),
        "p_pellet": (16, 16, 1, 1),
        "p_airbomb": (28, 48, 2, 2),
        "p_bomblet": (20, 20, 1, 1),
        "plane": (164, 72, 2, 2),
        "target": (64, 64, 2, 2),
    }

    all_sprites = {}

    for name, box in weapons_cells.items():
        cropped = im1.crop(box)
        sprite = extract_sprite(cropped)
        all_sprites[name] = sprite
        sprite.save(os.path.join(HIRES_DIR, f"{name}_hires.png"), "PNG")

    for name, box in projectiles_cells.items():
        cropped = im2.crop(box)
        sprite = extract_sprite(cropped)
        all_sprites[name] = sprite
        sprite.save(os.path.join(HIRES_DIR, f"{name}_hires.png"), "PNG")

    print("\nFitting and saving in-game sprites:")
    for name, sprite in all_sprites.items():
        tw, th, px, py = canvas_specs[name]
        canvas = fit_into_canvas(sprite, tw, th, px, py)
        dst_path = os.path.join(DEST_DIR, f"{name}.png")
        canvas.save(dst_path, "PNG", optimize=True)
        print(f"  [SAVED] {name}.png ({canvas.size[0]}x{canvas.size[1]})")

    print("\nAll 17 weapon and projectile sprites updated successfully!")


if __name__ == "__main__":
    main()
