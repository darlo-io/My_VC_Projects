"""Извлекает иконки из макета главного экрана (v3 — точные bbox).

Источник: 853×1844 px макет. Bounding boxes подобраны вручную по
изображению — круги с иконками лежат в указанных координатах.

Выход: assets/icons/home/{name}.png — PNG с прозрачным фоном
(белый/кремовый фон за пределами круга становится прозрачным).
Само отображение круглой формы берёт на себя UI-слой
(`BoxDecoration(shape: BoxShape.circle)`).
"""
from __future__ import annotations

import os

from PIL import Image

SRC = r"F:\My_VC_Projects\docs\images\75a732c8-bf91-4ca3-800f-ef035dbd4a2b.png"
OUT_DIR = r"F:\My_VC_Projects\quran_app\assets\icons\home"

# left, top, right, bottom, name
BBOXES: list[tuple[int, int, int, int, str]] = [
    # Шестерёнка (header).
    (40, 65, 130, 150, "settings"),
    # Коран на подставке (rehal) в _ContinueCard.
    (75, 595, 265, 815, "quran_rehal"),
    # Плитка «Читать» — открытая книга на подставке.
    (75, 825, 260, 1000, "read"),
    # Плитка «Слушать» — наушники.
    (460, 825, 635, 1000, "listen"),
    # Плитка «Учить» — шапочка выпускника.
    (75, 1115, 260, 1290, "learn"),
    # Плитка «Тест» — планшет с заметками.
    (460, 1115, 635, 1290, "test"),
    # Плитка «Тасбих» — чётки.
    (75, 1415, 260, 1585, "tasbih"),
    # Плитка «Статистика» — диаграмма.
    (460, 1415, 635, 1585, "stats"),
    # Навигация не извлекаем — для табов используем Material Icons,
    # которые уже встроены в Flutter (`Icons.home_outlined` и т.д.).
]

UPSCALEx = 2  # для xxxhdpi


def make_transparent(rgb_img: Image.Image, threshold: int = 252) -> Image.Image:
    """Светлый фон → прозрачный.

    На макете фон плиток очень светлый (mint, sand, sky-blue пастель),
    а сами объекты — насыщенные. `threshold=252` отсекает почти весь
    фон плитки, оставляя только сам объект и его тень.
    """
    rgba = rgb_img.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (255, 255, 255, 0)
            else:
                mn = min(r, g, b)
                if mn > 230:
                    k = (255 - mn) / 25.0
                    pixels[x, y] = (r, g, b, int(255 * min(1.0, k)))
    return rgba


def main() -> None:
    # Удаляем старые файлы, чтобы не оставалось мусора.
    if os.path.isdir(OUT_DIR):
        for fname in os.listdir(OUT_DIR):
            if fname.endswith(".png"):
                os.remove(os.path.join(OUT_DIR, fname))

    src = Image.open(SRC).convert("RGB")
    os.makedirs(OUT_DIR, exist_ok=True)

    for left, top, right, bottom, name in BBOXES:
        crop = src.crop((left, top, right, bottom))
        out = make_transparent(crop)

        if UPSCALEx != 1:
            out = out.resize(
                (out.width * UPSCALEx, out.height * UPSCALEx),
                Image.LANCZOS,
            )

        out_path = os.path.join(OUT_DIR, f"{name}.png")
        out.save(out_path, "PNG", optimize=True)
        size_kb = os.path.getsize(out_path) / 1024
        print(f"{name:<14} {out.width:>3}x{out.height:<3}  {size_kb:>5.1f} KB")


if __name__ == "__main__":
    main()