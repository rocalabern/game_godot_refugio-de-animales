# Refugio de animales

Prototipo 2D en Godot: salas de 20 x 12 casillas útiles, con una fila superior
adicional para el menú. El personaje se ve en 1 x 2, pero solo su base inferior
colisiona y decide Y-Sort, navegación y transiciones.

## Arquitectura de contenido

Cada sala usa un `RoomData`, con tres fuentes de contenido editables:

- `RoomGridData`: colisiones base pintadas en el editor.
- `PlacedObjectData`: escena y casilla base de cada objeto colocado.
- `RoomTransitionData`: puerta, sala destino y casilla de aparición.

`RoomOccupancy` combina automáticamente el grid base y los objetos para generar
la navegación nativa y las colisiones físicas. La sala no conoce tipos concretos
como gatos, mesas o alfombras.

```text
PlaceableObject
└── AnimalObject
    └── Cat
        └── CatSiames
```

Los muebles heredan directamente de `PlaceableObject`. Cada tipo declara las
casillas visuales, las que bloquea y las de interacción. Por ejemplo: un gato se
ve en 1 x 2 pero bloquea únicamente su base; una alfombra no bloquea nada.

## Añadir un objeto a una sala

1. Crea una escena que herede de `PlaceableObject` o `AnimalObject`.
2. Define en ella su huella, bloqueo y dibujo.
3. En el recurso `RoomData` de la sala, añade un `PlacedObjectData` con la escena
   y su `base_cell`.

No hace falta modificar navegación ni colisiones: se reconstruyen desde el
contrato del objeto.

## Pintar colisión base

1. Abre una escena dentro de `rooms/` en la vista **2D**.
2. Selecciona el nodo raíz de la sala.
3. Activa **Pintar colisiones** en el panel inferior **Colisiones de sala**.
4. Clic alterna el bloqueo: rojo significa bloqueado.

Las colisiones pintadas se guardan dentro del `RoomGridData` de cada escena.
