from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
IMG_DIR = ROOT / "artifacts" / "screenshots"


def split_vertical_image(src_name: str, part_names: list[str], overlap: int = 24) -> None:
    src_path = IMG_DIR / src_name
    image = Image.open(src_path)
    width, height = image.size
    part_count = len(part_names)
    base_height = height // part_count

    for index, part_name in enumerate(part_names):
        top = index * base_height
        bottom = height if index == part_count - 1 else (index + 1) * base_height
        if index > 0:
            top = max(0, top - overlap)
        if index < part_count - 1:
            bottom = min(height, bottom + overlap)
        cropped = image.crop((0, top, width, bottom))
        cropped.save(IMG_DIR / part_name)


def main() -> None:
    split_vertical_image(
        "lab3_result.png",
        ["lab3_result_part1.png", "lab3_result_part2.png", "lab3_result_part3.png"],
    )
    split_vertical_image(
        "lab4_queries_result.png",
        [
            "lab4_queries_result_part1.png",
            "lab4_queries_result_part2.png",
            "lab4_queries_result_part3.png",
        ],
    )


if __name__ == "__main__":
    main()
