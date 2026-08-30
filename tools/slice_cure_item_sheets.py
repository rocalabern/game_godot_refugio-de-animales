"""Recorta las hojas generadas del minijuego Curar en PNG individuales."""

from pathlib import Path
import sys

from PIL import Image


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
        canvas.save(destination / f"{name}.png", optimize=True)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Uso: slice_cure_item_sheets.py HOJA_MEDICA HOJA_COTIDIANA")
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
