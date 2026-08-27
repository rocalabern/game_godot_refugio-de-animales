# Colisiones lógicas

`collision_tileset.tres` contiene un único tile bloqueado. Es rojo solo para facilitar la edición y la capa `CollisionTiles` está oculta durante el juego.

- Pintar el tile rojo: pared o zona no transitable.
- Borrar una celda: suelo o puerta transitable.

El PNG de fondo nunca genera colisiones. `RoomController` usa `CollisionTiles` para construir navegación y cuerpos físicos.
