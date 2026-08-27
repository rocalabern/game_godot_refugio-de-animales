# Refugio de animales

Prototipo 2D en Godot: salas de 20 x 12 casillas útiles, con una fila superior
adicional para el menú. La resolución de diseño es 1008 x 624 (casillas de 48 px)
y Godot la escala manteniendo la proporción en PC, tablet y móvil. El personaje
se ve en 1 x 2, pero solo su base inferior colisiona y decide Y-Sort, navegación
y transiciones.

## Arquitectura de contenido

Cada sala usa un `RoomData` para sus objetos y tres capas `TileMapLayer` para su
mapa:

- `FloorTiles`: suelos caminables.
- `WallTiles`: paredes; cada tile de pared ya contiene su colisión.
- `ForegroundTiles`: decoración alta ordenada por Y.
- `PlacedObjectData`: escena y casilla base de cada objeto colocado.

El recurso compartido `assets/tiles/shelter/shelter_tileset.tres` es la fuente
de verdad de los tiles. Pintar una pared crea automáticamente su colisión;
pintar suelo no crea ninguna.

Las transiciones usan una instancia reutilizable de `Doorway` (`Area2D`) dentro
de cada escena de habitación. Cada puerta selecciona en el Inspector su escena
destino, el nombre del `Marker2D` de aparición y un sonido opcional.

`RoomOccupancy` combina automáticamente las paredes físicas del TileMap y los
objetos para generar navegación nativa. La sala no conoce tipos concretos como
gatos, mesas o alfombras.

```text
PlaceableObject
└── AnimalObject
    └── Cat
        └── CatSiames
```

Los muebles heredan directamente de `PlaceableObject`. Cada tipo declara las
casillas visuales, las que bloquea y las de interacción. Por ejemplo: un gato se
ve en 1 x 2 pero bloquea únicamente su base; una alfombra no bloquea nada.

## Datos y ficha de animales

`AnimalObject` centraliza los datos editables de cualquier animal: `tipo`,
`raza`, `edad`, `nombre`, `pet_name`, salud, hambre, higiene, felicidad y sus cuatro
características de personalidad. Al pulsar un animal, se abre directamente una
ficha modal que pausa el juego, sin mover al personaje.
La ficha muestra la identidad,
necesidades y una frase generada a partir de activo, sociable, dependiente y
adistramiento. Se cierra con la X grande o con `Esc`. Las bandas concretas de
cada característica están documentadas en `docs/architecture.md`.

## Añadir un objeto a una sala

1. Crea una escena que herede de `PlaceableObject` o `AnimalObject`.
2. Define en ella su huella, bloqueo y dibujo.
3. En el recurso `RoomData` de la sala, añade un `PlacedObjectData` con la escena
   y su `base_cell`.

No hace falta modificar navegación ni colisiones: se reconstruyen desde el
contrato del objeto.

## Crear una puerta entre habitaciones

1. Instancia `systems/transitions/doorway.tscn` en la habitación de origen.
2. Define su zona de grid, dirección de entrada, escena de destino y el ID del
   punto de aparición.
3. En la habitación de destino, añade un `Marker2D` con ese ID como nombre y
   muévelo directamente a la posición de aparición deseada.

La puerta inversa es otra instancia `Doorway` configurada explícitamente.

## Pintar una habitación

1. Abre la escena de la habitación en la vista **2D**.
2. Selecciona `FloorTiles`, `WallTiles` o `ForegroundTiles`.
3. En el panel inferior **TileMap**, elige un tile del TileSet.
4. Pinta normalmente. Las paredes bloquean; los suelos no.

Para una puerta, borra los tiles de `WallTiles` que forman su hueco y ajusta la
instancia `Doorway` que está sobre él.
