"""Create one 21x13 Godot TileSet per generated room template.

Each atlas cell is deliberately a distinct tile. Repainting every cell at its
original coordinate reconstructs its source room exactly. This is a template
tileset, not a freely combinable modular kit.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/tiles/template_rooms"
STYLES = ("walnut_cream", "oak_sand", "chestnut_stone")
WIDTH, HEIGHT, CELL = 21, 13, 48


def is_door(x: int, y: int) -> bool:
    # All four three-cell doors cut through the two-cell structural border.
    return (
        x in (9, 10, 11) and y in (0, 1, HEIGHT - 2, HEIGHT - 1)
        or y in (5, 6, 7) and x in (0, 1, WIDTH - 2, WIDTH - 1)
    )


def is_solid(x: int, y: int) -> bool:
    return not is_door(x, y) and (x < 2 or x >= WIDTH - 2 or y < 2 or y >= HEIGHT - 2)


def create_tileset(style: str) -> None:
    lines = [
        "[gd_resource type=\"TileSet\" format=3]",
        "",
        f'[ext_resource type="Texture2D" path="res://assets/tiles/template_rooms/{style}_atlas_48.png" id="1_atlas"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_template"]',
        'texture = ExtResource("1_atlas")',
        f"texture_region_size = Vector2i({CELL}, {CELL})",
    ]
    for y in range(HEIGHT):
        for x in range(WIDTH):
            lines.append(f"{x}:{y}/0 = 0")
            if is_solid(x, y):
                lines.append(
                    f"{x}:{y}/0/physics_layer_0/polygon_0/points = "
                    "PackedVector2Array(0, 0, 48, 0, 48, 48, 0, 48)"
                )
    lines.extend(
        [
            "",
            "[resource]",
            f"tile_size = Vector2i({CELL}, {CELL})",
            "physics_layer_0/collision_layer = 1",
            "sources/0 = SubResource(\"TileSetAtlasSource_template\")",
            "",
        ]
    )
    (BASE / f"{style}_template_tileset.tres").write_text("\n".join(lines), encoding="utf-8")


for style_name in STYLES:
    create_tileset(style_name)
    print(BASE / f"{style_name}_template_tileset.tres")
