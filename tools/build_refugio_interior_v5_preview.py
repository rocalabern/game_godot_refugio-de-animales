"""Build a 21x13 proof map by cropping the actual v5 atlas.

The map is intentionally a mechanical test: it lets us see whether every edge
of the atlas aligns before anyone paints a real room in Godot.
"""

from pathlib import Path
import json
import re


ROOT = Path(__file__).resolve().parents[1]
TILESET = ROOT / "assets/tiles/refugio_interior_v5/refugio_interior_v5_tileset.tres"
OUTPUT = ROOT / "assets/tiles/refugio_interior_v5/refugio_interior_v5_layout_test.svg"
MAP_OUTPUT = ROOT / "assets/tiles/refugio_interior_v5/refugio_interior_v5_layout_test.json"
CELL = 48
WIDTH, HEIGHT = 21, 13

# Atlas coordinates, taken from the v5 TileSet source.
FLOOR = (0, 0)
SOLID = (2, 0)
SOLID_LEFT = (5, 0)
SOLID_RIGHT = (6, 0)
FRONT = (3, 1)
DOOR_LEFT = (6, 1)
DOOR_MIDDLE = (7, 1)
DOOR_RIGHT = (0, 2)


def tile(x: int, y: int, source: tuple[int, int], index: int) -> tuple[str, str]:
    sx, sy = source[0] * CELL, source[1] * CELL
    clip_id = f"tile_clip_{index}"
    clip = f'<clipPath id="{clip_id}"><rect x="{x * CELL}" y="{y * CELL}" width="{CELL}" height="{CELL}"/></clipPath>'
    image = (
        f'<g clip-path="url(#{clip_id})" transform="translate({x * CELL - sx} {y * CELL - sy})">'
        '<use href="#v5_atlas"/></g>'
    )
    return clip, image


def main() -> None:
    tileset_text = TILESET.read_text(encoding="utf-8")
    match = re.search(r'path="res://assets/tiles/refugio_interior_v5/([^\"]+)"', tileset_text)
    if match is None:
        raise RuntimeError("No encuentro el atlas definido por el TileSet v5.")
    atlas_filename = match.group(1)
    atlas_path = TILESET.parent / atlas_filename
    atlas_source = atlas_path.read_text(encoding="utf-8")
    atlas_inner = re.sub(r"^<svg[^>]*>|</svg>\s*$", "", atlas_source.strip(), flags=re.DOTALL)
    defs_end = atlas_inner.find("</defs>") + len("</defs>")
    atlas_defs = atlas_inner[:defs_end]
    atlas_body = atlas_inner[defs_end:]

    cells: dict[tuple[int, int], tuple[int, int]] = {}
    for y in range(HEIGHT):
        for x in range(WIDTH):
            cells[(x, y)] = FLOOR

    # Solid outer mass: top and bottom. The exposed face is the row immediately
    # under the top mass. The two side walls stay solid for the room height.
    for x in range(WIDTH):
        cells[(x, 0)] = SOLID
        cells[(x, HEIGHT - 1)] = SOLID
    for y in range(1, HEIGHT - 1):
        cells[(0, y)] = SOLID_LEFT
        cells[(WIDTH - 1, y)] = SOLID_RIGHT
    for x in range(1, WIDTH - 1):
        cells[(x, 1)] = FRONT

    # One centred three-cell doorway in the front wall.
    door_x = WIDTH // 2 - 1
    cells[(door_x, 1)] = DOOR_LEFT
    cells[(door_x + 1, 1)] = DOOR_MIDDLE
    cells[(door_x + 2, 1)] = DOOR_RIGHT

    tiles = [tile(x, y, source, index) for index, ((x, y), source) in enumerate(cells.items())]
    clip_defs = "\n".join(clip for clip, _image in tiles)
    body = "\n".join(image for _clip, image in tiles)
    OUTPUT.write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH * CELL}" height="{HEIGHT * CELL}" '
        f'viewBox="0 0 {WIDTH * CELL} {HEIGHT * CELL}">\n'
        f'{atlas_defs}\n<defs><g id="v5_atlas">{atlas_body}</g>{clip_defs}</defs>\n{body}\n</svg>\n',
        encoding="utf-8",
    )
    MAP_OUTPUT.write_text(
        json.dumps(
            {
                "atlas": f"assets/tiles/refugio_interior_v5/{atlas_filename}",
                "cell_size": CELL,
                "width": WIDTH,
                "height": HEIGHT,
                "cells": [
                    {"x": x, "y": y, "atlas_x": source[0], "atlas_y": source[1]}
                    for (x, y), source in cells.items()
                ],
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(OUTPUT)
    print(MAP_OUTPUT)


if __name__ == "__main__":
    main()
