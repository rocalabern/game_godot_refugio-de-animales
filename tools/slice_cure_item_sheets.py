"""Recorta las hojas generadas del minijuego Curar en PNG individuales."""

from pathlib import Path
import sys

from PIL import Image


def remove_tiny_alpha_islands(image: Image.Image) -> Image.Image:
    """Elimina restos aislados del generador sin tocar piezas relevantes."""
    alpha = image.getchannel("A")
    alpha_pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for y in range(image.height):
        for x in range(image.width):
            if alpha_pixels[x, y] < 16 or (x, y) in visited:
                continue
            component: list[tuple[int, int]] = []
            pending = [(x, y)]
            visited.add((x, y))
            while pending:
                current_x, current_y = pending.pop()
                component.append((current_x, current_y))
                for offset_x, offset_y in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    neighbor = (current_x + offset_x, current_y + offset_y)
                    if (
                        neighbor not in visited
                        and 0 <= neighbor[0] < image.width
                        and 0 <= neighbor[1] < image.height
                        and alpha_pixels[neighbor[0], neighbor[1]] >= 16
                    ):
                        visited.add(neighbor)
                        pending.append(neighbor)
            components.append(component)
    if not components:
        return image
    minimum_area = max(16, int(max(map(len, components)) * 0.03))
    pixels = image.load()
    for component in components:
        if len(component) < minimum_area:
            for position in component:
                pixels[position] = (0, 0, 0, 0)
    return image


def slice_sheet(source: Path, destination: Path, names: list[str], columns: int) -> None:
    sheet = Image.open(source).convert("RGBA")
    rows = (len(names) + columns - 1) // columns
    cell_width = sheet.width // columns
    cell_height = sheet.height // rows
    destination.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(names):
        x = (index % columns) * cell_width
        y = (index // columns) * cell_height
        item = sheet.crop((x, y, x + cell_width, y + cell_height))
        alpha_bounds = item.getchannel("A").getbbox()
        if alpha_bounds:
            item = item.crop(alpha_bounds)
        item.thumbnail((224, 224), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        canvas.alpha_composite(item, ((256 - item.width) // 2, (256 - item.height) // 2))
        canvas = remove_tiny_alpha_islands(canvas)
        canvas.save(destination / f"{name}.png", optimize=True)


if __name__ == "__main__":
    if len(sys.argv) not in (3, 5):
        raise SystemExit("Uso: slice_cure_item_sheets.py HOJA_MEDICA HOJA_COTIDIANA [HOJA_MEDICA_2 HOJA_COTIDIANA_2]")
    root = Path(__file__).resolve().parents[1]
    slice_sheet(Path(sys.argv[1]), root / "assets/minigames/cure/medical", [
        "stethoscope", "capsule", "head_mirror", "tongue_depressor",
        "thermometer", "syringe", "bandage_roll", "otoscope",
    ], 4)
    slice_sheet(Path(sys.argv[2]), root / "assets/minigames/cure/distractors", [
        "jump_rope", "candy", "pocket_mirror", "ice_pop_stick",
        "pen", "water_pistol", "rolled_sock", "flashlight",
        "ball", "spoon", "ruler", "clothespin",
        "paper_clips", "pencil", "calculator", "comb",
    ], 4)
    if len(sys.argv) == 5:
        slice_sheet(Path(sys.argv[3]), root / "assets/minigames/cure/medical", [
            "reflex_hammer", "medicine_dropper", "cone_collar", "medical_tweezers",
        ], 4)
        slice_sheet(Path(sys.argv[4]), root / "assets/minigames/cure/distractors", [
            "toy_mallet", "glue_bottle", "party_hat", "kitchen_tongs",
            "keyring", "wristwatch", "toy_car", "rubber_duck",
            "mug", "mitten", "banana", "padlock",
            "paint_brush", "magnifying_glass", "bell", "cassette_tape",
        ], 4)
