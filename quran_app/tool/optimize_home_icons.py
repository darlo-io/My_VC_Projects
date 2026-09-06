"""Одноразовая оптимизация home-иконок: PNG → WebP + даунскейл.

Фаза C1 оптимизации размера приложения (2026-08-14).

Исходники `assets/icons/home/*.png` (370×350 px, 66–152 КБ каждый)
отображаются в боксах 20–64 dp — даже на 3x-экране нужно ≤192 px.
Конвертируем в WebP (Pillow) и заменяем исходники.

Запуск: `py tool/optimize_home_icons.py`
"""

from pathlib import Path

from PIL import Image

ICONS_DIR = Path(__file__).resolve().parent.parent / "assets" / "icons" / "home"
MAX_SIDE = 192
QUALITY = 90


def main() -> None:
    total_before = 0
    total_after = 0
    for png in sorted(ICONS_DIR.glob("*.png")):
        before = png.stat().st_size
        total_before += before
        with Image.open(png) as im:
            im = im.convert("RGBA")
            im.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
            webp = png.with_suffix(".webp")
            im.save(webp, "WEBP", quality=QUALITY, method=6)
        png.unlink()
        after = webp.stat().st_size
        total_after += after
        print(f"{png.name} ({before / 1024:.0f} KB) -> "
              f"{webp.name} ({after / 1024:.1f} KB)")
    print(f"TOTAL: {total_before / 1024:.0f} KB -> {total_after / 1024:.0f} KB")


if __name__ == "__main__":
    main()
