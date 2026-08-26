# Room assets

Place these two **PNG** files in this folder, both at **1152 × 648 pixels**:

- `room_background.png`: the visible room.
- `room_collision.png`: its collision mask, aligned pixel-for-pixel with the background. Use solid black for blocking objects (the table) and white everywhere the player may walk.

The game loads both automatically. Click to move the blue square; it will stop against black areas of the collision mask. Set `show_collision_mask` to `true` on the Main node to inspect the mask in-game.
