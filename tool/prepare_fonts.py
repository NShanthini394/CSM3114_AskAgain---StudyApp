"""Rebuild bundled font instances: pip install fonttools==4.68.0; python tool/prepare_fonts.py.

Static instances let Flutter select 400/600/700 without synthetic bold.
The source commit is pinned so later Google Fonts updates cannot change builds.
"""
from io import BytesIO
from pathlib import Path
from urllib.parse import quote
from urllib.request import urlopen

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

COMMIT = "cc5661d43cd4f9aad5567033a8e15ca28dc35c86"
FONTS = {
    "Inter": ("inter", "Inter[opsz,wght].ttf"),
    "Roboto": ("roboto", "Roboto[wdth,wght].ttf"),
    "OpenSans": ("opensans", "OpenSans[wdth,wght].ttf"),
    "Lexend": ("lexend", "Lexend[wght].ttf"),
    "LibreBaskerville": ("librebaskerville", "LibreBaskerville[wght].ttf"),
}
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "fonts"

for family, (directory, filename) in FONTS.items():
    base = f"https://raw.githubusercontent.com/google/fonts/{COMMIT}/ofl/{directory}/"
    with urlopen(base + quote(filename), timeout=60) as response:
        data = response.read()
    destination = OUTPUT / family
    destination.mkdir(parents=True, exist_ok=True)
    with urlopen(base + "OFL.txt", timeout=60) as response:
        (destination / "OFL.txt").write_bytes(response.read())
    for weight, style in [(400, "Regular"), (600, "SemiBold"), (700, "Bold")]:
        font = TTFont(BytesIO(data))
        axes = {axis.axisTag: axis.defaultValue for axis in font["fvar"].axes}
        axes["wght"] = weight
        instance = instantiateVariableFont(font, axes, inplace=True)
        instance.save(destination / f"{style}.ttf")
        print(f"Prepared {family} {style}")
