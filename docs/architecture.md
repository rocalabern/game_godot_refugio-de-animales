# Arquitectura de juego

## Flujo de una habitación

`GameController` carga una escena de habitación y le pasa el tamaño real de
casilla. `ShelterRoom` lee su `RoomData`, instancia sus `PlacedObjectData` y
construye un `RoomOccupancy`.

`RoomOccupancy` es la fuente única de verdad de las casillas bloqueadas. A partir
de ella se crean `NavigationRegion2D` y las colisiones generadas. Un objeto que
ya ofrece su propio `StaticBody2D`, como un animal, se excluye únicamente de las
colisiones generadas; sigue incluido en la navegación.

## Contratos

`PlaceableObject` define ubicación, huella, navegación e interacción. La casilla
de base corresponde al origen del nodo en el suelo; cada subclase puede declarar
casillas relativas para representarse de otro modo.

`AnimalObject` añade necesidades comunes. Las clases de especie, como `Cat`, no
deben ser consultadas por una habitación: se colocan mediante `PlacedObjectData`.

## Datos editables

- `RoomGridData`: bloqueos fijos del fondo, pintados en el editor.
- `PlacedObjectData`: escena e identidad de un objeto colocado.
- `RoomData`: agrupa los datos de suelo y objetos por habitación.

Las puertas no están en `RoomData`: son instancias `Doorway` (`Area2D`) que se
ven y se configuran dentro de la escena. Señalan al `GameController`, que
conserva al jugador, carga la sala destino y lo sitúa en el `Marker2D` solicitado.
