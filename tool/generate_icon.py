"""Generate launcher PNGs for flutter_launcher_icons.

Mirrors the design of public/icon-512.svg: dark rounded-rect with a stylized
dumbbell centered on it. We draw the dumbbell procedurally instead of relying
on an emoji font so the output is identical everywhere Python runs.
"""

from PIL import Image, ImageDraw
from pathlib import Path


BG = (15, 17, 23, 255)            # #0f1117
ACCENT = (239, 68, 68, 255)        # #ef4444 (tailwind red-500, from the SVG)
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "icons"


def rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_dumbbell(img, size, color):
    """Draw a dumbbell centered on `img`. Proportions scale with size."""
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2

    # Bar: horizontal rounded rect.
    bar_w = size * 0.48
    bar_h = size * 0.08
    d.rounded_rectangle(
        (cx - bar_w / 2, cy - bar_h / 2, cx + bar_w / 2, cy + bar_h / 2),
        radius=bar_h / 2,
        fill=color,
    )

    # Inner weight plates: chunky rounded rects close to the bar.
    inner_w = size * 0.085
    inner_h = size * 0.30
    inner_offset = size * 0.20
    for side in (-1, 1):
        x = cx + side * inner_offset
        d.rounded_rectangle(
            (x - inner_w / 2, cy - inner_h / 2, x + inner_w / 2, cy + inner_h / 2),
            radius=size * 0.025,
            fill=color,
        )

    # Outer weight plates: slightly smaller, at the tips.
    outer_w = size * 0.075
    outer_h = size * 0.22
    outer_offset = size * 0.295
    for side in (-1, 1):
        x = cx + side * outer_offset
        d.rounded_rectangle(
            (x - outer_w / 2, cy - outer_h / 2, x + outer_w / 2, cy + outer_h / 2),
            radius=size * 0.02,
            fill=color,
        )


def render(size, corner_radius, path, *, bg=BG, transparent_bg=False):
    # Draw on a 4x supersampled canvas then downscale for clean edges.
    scale = 4
    big = size * scale
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    if not transparent_bg:
        draw_bg = ImageDraw.Draw(layer)
        draw_bg.rounded_rectangle(
            (0, 0, big - 1, big - 1),
            radius=corner_radius * scale,
            fill=bg,
        )
    draw_dumbbell(layer, big, ACCENT)
    layer = layer.resize((size, size), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    layer.save(path, "PNG")
    print(f"wrote {path} ({size}x{size})")


if __name__ == "__main__":
    # Main launcher icon (legacy + fallback).
    render(1024, corner_radius=160, path=OUT_DIR / "icon.png")
    # Adaptive foreground — transparent background, dumbbell centered.
    render(1024, corner_radius=0, path=OUT_DIR / "icon_foreground.png", transparent_bg=True)
