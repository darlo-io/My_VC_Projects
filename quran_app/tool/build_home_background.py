"""Готовит фоновую картинку главного экрана в формате WebP.

Источник: docs/images/background.webp (941×1672).
Цель: assets/images/backgrounds/home_background.webp (1080×2400).

Алгоритм:
  1. Целевое полотно 1080×2400 с кремовым фоном `AppColors.background`.
  2. Исходник 941×1672 помещается **целиком** по центру горизонтально
     (отступы ~70px слева/справа) и сверху по вертикали. Снизу
     добавляется кремовое поле 728px — на исходнике внизу однородный
     светлый фон, поэтому граница будет незаметна.

В UI используется `BoxFit.cover` с `alignment: topRight` —
мечеть остаётся в правом верхнем углу на любых пропорциях экрана.
"""
from __future__ import annotations

import os

from PIL import Image

SRC = r"F:\My_VC_Projects\docs\images\background.webp"
DST = r"F:\My_VC_Projects\quran_app\assets\images\backgrounds\home_background.webp"

W, H = 1080, 2400
# Кремовый фон приложения (AppColors.background = #FAF7F0).
BG = (250, 247, 240)


def main() -> None:
    src = Image.open(SRC).convert("RGB")
    sw, sh = src.size  # 941×1672

    # Целевое полотно с кремовым фоном.
    canvas = Image.new("RGB", (W, H), BG)

    # Размещаем исходник по центру горизонтально, сверху по вертикали.
    x_offset = (W - sw) // 2
    y_offset = 0
    canvas.paste(src, (x_offset, y_offset))

    os.makedirs(os.path.dirname(DST), exist_ok=True)
    canvas.save(DST, "WEBP", quality=82, method=6)

    size_kb = os.path.getsize(DST) / 1024
    print(f"Saved: {DST} ({W}x{H}, src={sw}x{sh}, {size_kb:.1f} KB)")
    print(f"Padding: left={x_offset}px, right={W - sw - x_offset}px, "
          f"bottom={H - sh}px")


if __name__ == "__main__":
    main()