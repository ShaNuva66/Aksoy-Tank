from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "assets" / "ui"
STORE_ICONS_DIR = ROOT / "assets" / "store" / "icons"
STORE_LISTING_DIR = ROOT / "assets" / "store" / "listing"

BG = (6, 8, 12, 255)
BG_ALT = (15, 20, 27, 255)
SURFACE = (19, 24, 31, 255)
ACCENT = (243, 200, 104, 255)
ACCENT_SOFT = (255, 230, 168, 255)
EYE = (255, 218, 108, 255)
CAT = (4, 5, 7, 255)
CAT_SOFT = (13, 16, 20, 255)


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_crescent(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, bg_fill: tuple[int, int, int, int]) -> None:
    x, y = center
    bbox = (x - radius, y - radius, x + radius, y + radius)
    draw.ellipse(bbox, fill=(ACCENT[0], ACCENT[1], ACCENT[2], 60))
    draw.ellipse((x - radius * 0.78, y - radius * 0.78, x + radius * 0.78, y + radius * 0.78), fill=ACCENT)
    draw.ellipse((x - radius * 0.34, y - radius * 0.86, x + radius * 1.06, y + radius * 0.54), fill=bg_fill)


def cat_geometry(size: int) -> dict[str, float]:
    return {
        "cx": size * 0.5,
        "cy": size * 0.56,
        "head_r": size * 0.17,
        "body_r": size * 0.18,
        "body_y": size * 0.72,
    }


def draw_cat(draw: ImageDraw.ImageDraw, size: int, fill: tuple[int, int, int, int], eye_color: tuple[int, int, int, int] | None, include_body: bool = True) -> None:
    g = cat_geometry(size)
    cx = g["cx"]
    cy = g["cy"]
    head_r = g["head_r"]
    body_r = g["body_r"]
    body_y = g["body_y"]

    if include_body:
        draw.ellipse((cx - body_r, body_y - body_r, cx + body_r, body_y + body_r * 0.94), fill=fill)

    draw.ellipse((cx - head_r, cy - head_r, cx + head_r, cy + head_r), fill=fill)

    left_ear = [
        (cx - head_r * 0.88, cy - head_r * 0.18),
        (cx - head_r * 0.46, cy - head_r * 1.28),
        (cx - head_r * 0.06, cy - head_r * 0.12),
    ]
    right_ear = [
        (cx + head_r * 0.88, cy - head_r * 0.18),
        (cx + head_r * 0.46, cy - head_r * 1.28),
        (cx + head_r * 0.06, cy - head_r * 0.12),
    ]
    draw.polygon(left_ear, fill=fill)
    draw.polygon(right_ear, fill=fill)

    tail_w = size * 0.03
    draw.arc(
        (cx + body_r * 0.2, body_y - body_r * 0.08, cx + body_r * 1.6, body_y + body_r * 1.28),
        start=258,
        end=58,
        fill=fill,
        width=max(4, int(tail_w)),
    )

    if eye_color:
        eye_w = head_r * 0.18
        eye_h = head_r * 0.26
        left_eye = (cx - head_r * 0.48 - eye_w * 0.5, cy - eye_h * 0.2, cx - head_r * 0.48 + eye_w * 0.5, cy + eye_h)
        right_eye = (cx + head_r * 0.48 - eye_w * 0.5, cy - eye_h * 0.2, cx + head_r * 0.48 + eye_w * 0.5, cy + eye_h)
        draw.ellipse(left_eye, fill=eye_color)
        draw.ellipse(right_eye, fill=eye_color)
        pupil = (35, 27, 10, 255)
        left_pupil_x = cx - head_r * 0.48
        right_pupil_x = cx + head_r * 0.48
        draw.line((left_pupil_x, cy - eye_h * 0.12, left_pupil_x, cy + eye_h * 0.9), fill=pupil, width=max(2, int(size * 0.008)))
        draw.line((right_pupil_x, cy - eye_h * 0.12, right_pupil_x, cy + eye_h * 0.9), fill=pupil, width=max(2, int(size * 0.008)))


def make_full_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), BG)
    img.putalpha(255)
    mask = rounded_mask(size, int(size * 0.19))
    draw = ImageDraw.Draw(img)

    for band in range(12):
        y0 = int(size * band / 12)
        y1 = int(size * (band + 1) / 12) + 2
        mix = band / 11
        color = tuple(int(BG[i] + (BG_ALT[i] - BG[i]) * mix) for i in range(3)) + (255,)
        draw.rectangle((0, y0, size, y1), fill=color)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    moon_center = (size * 0.72, size * 0.26)
    moon_r = size * 0.16
    glow_draw.ellipse((moon_center[0] - moon_r, moon_center[1] - moon_r, moon_center[0] + moon_r, moon_center[1] + moon_r), fill=(ACCENT[0], ACCENT[1], ACCENT[2], 110))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=size * 0.035))
    img.alpha_composite(glow)

    draw_crescent(draw, moon_center, moon_r * 0.82, BG_ALT)
    draw_cat(draw, size, CAT, EYE, include_body=True)

    rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    rim_draw.rounded_rectangle((int(size * 0.02), int(size * 0.02), int(size * 0.98), int(size * 0.98)), radius=int(size * 0.18), outline=(255, 237, 190, 36), width=max(2, int(size * 0.012)))
    img.alpha_composite(rim)
    img.putalpha(mask)
    return img


def make_adaptive_background(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(img)
    for band in range(10):
        y0 = int(size * band / 10)
        y1 = int(size * (band + 1) / 10) + 2
        mix = band / 9
        color = tuple(int(BG[i] + (SURFACE[i] - BG[i]) * mix) for i in range(3)) + (255,)
        draw.rectangle((0, y0, size, y1), fill=color)
    draw_crescent(draw, (size * 0.72, size * 0.24), size * 0.14, SURFACE)
    return img


def make_adaptive_foreground(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_cat(draw, size, CAT_SOFT, EYE, include_body=True)
    return img


def make_adaptive_monochrome(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_cat(draw, size, (248, 239, 219, 255), None, include_body=True)
    return img


def save() -> None:
    UI_DIR.mkdir(parents=True, exist_ok=True)
    STORE_ICONS_DIR.mkdir(parents=True, exist_ok=True)
    STORE_LISTING_DIR.mkdir(parents=True, exist_ok=True)

    make_full_icon(512).save(UI_DIR / "icon.png")
    make_full_icon(192).save(STORE_ICONS_DIR / "android-main-192.png")
    make_adaptive_background(432).save(STORE_ICONS_DIR / "android-adaptive-background-432.png")
    make_adaptive_foreground(432).save(STORE_ICONS_DIR / "android-adaptive-foreground-432.png")
    make_adaptive_monochrome(432).save(STORE_ICONS_DIR / "android-adaptive-monochrome-432.png")
    make_full_icon(512).save(STORE_LISTING_DIR / "google-play-icon-512.png")


if __name__ == "__main__":
    save()
    print("BLACK_CAT_ICONS_READY")
