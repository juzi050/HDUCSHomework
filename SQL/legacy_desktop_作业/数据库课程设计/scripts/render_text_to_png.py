from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import sys


def load_font(size: int):
    candidates = [
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simsun.ttc",
        r"C:\Windows\Fonts\consola.ttf",
        r"C:\Windows\Fonts\CascadiaMono.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def render_file(text_path: Path, image_path: Path) -> None:
    text = text_path.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines() or [""]

    font = load_font(20)
    line_height = 30
    padding_x = 24
    padding_y = 24
    max_width = 0

    dummy = Image.new("RGB", (1, 1), "white")
    draw = ImageDraw.Draw(dummy)

    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        max_width = max(max_width, bbox[2] - bbox[0])

    width = min(max_width + padding_x * 2, 1800)
    height = max(line_height * len(lines) + padding_y * 2, 200)

    image = Image.new("RGB", (width, height), "#0b1220")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((8, 8, width - 8, height - 8), radius=16, outline="#2dd4bf", width=2, fill="#0f172a")

    y = padding_y
    for line in lines:
        draw.text((padding_x, y), line, font=font, fill="#e5e7eb")
        y += line_height

    image_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(image_path)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: python render_text_to_png.py <input.txt> <output.png>")
    render_file(Path(sys.argv[1]), Path(sys.argv[2]))
