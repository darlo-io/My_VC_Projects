"""Add app_colors.dart import to files that use AppColors but don't import it."""
import os

files = [
    r'F:\My_VC_Projects\quran_app\lib\features\onboarding\presentation\language_picker_screen.dart',
    r'F:\My_VC_Projects\quran_app\lib\features\statistics\presentation\statistics_screen.dart',
    r'F:\My_VC_Projects\quran_app\lib\shared\widgets\progress_ring.dart',
    r'F:\My_VC_Projects\quran_app\lib\shared\widgets\juz_progress_circle.dart',
    r'F:\My_VC_Projects\quran_app\lib\app\router\app_router.dart',
]

LIB_ROOT = r'F:\My_VC_Projects\quran_app\lib'

for f in files:
    with open(f, 'r', encoding='utf-8') as fp:
        s = fp.read()

    # Skip if already imports app_colors
    if "core/theme/app_colors" in s:
        print(f"SKIP (has import): {f}")
        continue

    # Skip if doesn't use AppColors
    if "AppColors" not in s:
        print(f"SKIP (no usage): {f}")
        continue

    # Compute relative path from file to lib/core/theme/app_colors.dart
    rel = os.path.relpath(
        os.path.join(LIB_ROOT, 'core', 'theme', 'app_colors.dart'),
        os.path.dirname(f),
    ).replace(os.sep, '/')

    import_line = f"import '{rel}';"

    # Insert after the first flutter/material import
    marker = "import 'package:flutter/material.dart';"
    if marker not in s:
        print(f"SKIP no marker: {f}")
        continue

    new = s.replace(marker, marker + '\n' + import_line, 1)
    with open(f, 'w', encoding='utf-8') as fp:
        fp.write(new)
    print(f"added import: {f.replace(LIB_ROOT + os.sep, '')}")