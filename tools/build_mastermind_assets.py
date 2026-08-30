"""Normaliza las creatividades de Cura v2 y genera cápsulas idénticas por tono."""

from colorsys import hsv_to_rgb, rgb_to_hsv
from pathlib import Path
import sys

from PIL import Image


CAPSULE_HUES = {
    "red": 0.99,
    "yellow": 0.15,
    "blue": 0.59,
    "lilac": 0.76,
    "orange": 0.075,
    "pink": 0.92,
}


def clean_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            normalized_alpha = max(0, min(255, round((alpha - 42) * 255 / 213)))
            pixels[x, y] = (red, green, blue, normalized_alpha)
    return image


def normalize(image: Image.Image, maximum_size: tuple[int, int]) -> Image.Image:
    image = clean_alpha(image)
    bounds = image.getchannel("A").point(lambda alpha: 255 if alpha >= 16 else 0).getbbox()
    if bounds:
        image = image.crop(bounds)
    image.thumbnail(maximum_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((256 - image.width) // 2, (256 - image.height) // 2))
    return canvas


def recolor(image: Image.Image, target_hue: float) -> Image.Image:
    result = image.copy()
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                continue
            _, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
            if saturation > 0.12:
                new_red, new_green, new_blue = hsv_to_rgb(target_hue, saturation, value)
                pixels[x, y] = (round(new_red * 255), round(new_green * 255), round(new_blue * 255), alpha)
    return result


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Uso: build_mastermind_assets.py CAPSULA HUESO_DORADO HUESO_PLATEADO")
    project_root = Path(__file__).resolve().parents[1]
    capsule_directory = project_root / "assets/minigames/cure_mastermind/capsules"
    feedback_directory = project_root / "assets/minigames/cure_mastermind/feedback"
    capsule_directory.mkdir(parents=True, exist_ok=True)
    feedback_directory.mkdir(parents=True, exist_ok=True)
    master_capsule = normalize(Image.open(sys.argv[1]), (224, 112))
    for name, hue in CAPSULE_HUES.items():
        recolor(master_capsule, hue).save(capsule_directory / f"{name}.png", optimize=True)
    normalize(Image.open(sys.argv[2]), (150, 90)).save(feedback_directory / "golden_bone.png", optimize=True)
    normalize(Image.open(sys.argv[3]), (150, 90)).save(feedback_directory / "silver_bone.png", optimize=True)
