# Arquitectura de juego

## Flujo de una habitación

`GameController` trabaja con una resolución virtual fija de 1008 x 624 y una
casilla de 48 px. `ShelterRoom` lee su `RoomData`, las capas `TileMapLayer` de la
escena, instancia sus `PlacedObjectData` y construye un `RoomOccupancy`.

Las colisiones estáticas pertenecen a los tiles de pared del `TileSet` y Godot
las genera automáticamente en `WallTiles`. `RoomOccupancy` lee esos tiles y
combina sus celdas con los objetos dinámicos para construir el
`NavigationRegion2D`. Las colisiones generadas solo se usan para objetos que no
aportan su propio `StaticBody2D`; un animal sigue aportando física y navegación
por medio de su contrato.

## Contratos

`PlaceableObject` define ubicación, huella, navegación e interacción. La casilla
de base corresponde al origen del nodo en el suelo; cada subclase puede declarar
casillas relativas para representarse de otro modo.

`AnimalObject` añade necesidades comunes. Las clases de especie, como `Cat`, no
deben ser consultadas por una habitación: se colocan mediante `PlacedObjectData`.

`AnimalObject` contiene los datos de identidad (`tipo`, `raza`, `edad`,
`nombre`, `pet_name`), necesidades (`salud`, `hambre`, `higiene`, `felicidad`, `energia`) y las cuatro
características de personalidad. La ficha modal `AnimalProfile` usa únicamente
este contrato: muestra identidad y necesidades, y genera una frase a partir de
activo, sociable, dependiente y adistramiento. Los valores de 41 a 59 reciben
una etiqueta neutral para que la frase siempre tenga un resultado.

### Reglas de `AnimalObject`

- `tipo`: `Cat`, `Dog`, `Rabbit` u `Owl`.
- `raza`: actualmente `Siames`.
- `edad`, necesidades y características: valores entre 0 y 100.
- `nombre`: nombre descriptivo del animal.
- `pet_name`: nombre individual mostrado como título de su ficha; si está vacío,
  la ficha muestra `nombre`.
- `receive_care()`: acción reutilizable de cuidado; aumenta salud, hambre,
  higiene, energía y felicidad, sin superar 100.

La descripción aplica estas bandas a cada característica:

| Característica | 0–19 | 20–40 | 41–59 | 60–80 | 81–100 |
|---|---|---|---|---|---|
| Activo | muy tranquilo | tranquilo | equilibrado | nervioso | muy nervioso |
| Sociable | muy poco empático | poco empático | equilibrado | empático | muy empático |
| Dependiente | muy independiente | independiente | equilibrado | cariñoso | muy cariñoso |
| Adistramiento | muy rebelde | rebelde | en aprendizaje | obediente | adiestrado |

Por ejemplo, la ficha puede generar: “Este gato es nervioso, empático,
cariñoso y rebelde.” El sustantivo inicial se obtiene de `tipo`.

## Datos editables

- `shelter_tileset.tres`: reglas reutilizables de visual, colisión y futuras
  propiedades de cada tile.
- `FloorTiles`, `WallTiles`, `ForegroundTiles`: mapa pintado de cada sala.
- `PlacedObjectData`: escena e identidad de un objeto colocado.
- `RoomData`: identidad y objetos de una habitación.

Las puertas no están en `RoomData`: son instancias `Doorway` (`Area2D`) que se
ven y se configuran dentro de la escena. Señalan al `GameController`, que
conserva al jugador, carga la sala destino y lo sitúa en el `Marker2D` solicitado.

## Minijuego de recogida de animales

`minigames/animal_pickup` es un módulo independiente de salas, navegación,
animales colocados y personaje. `GameController` instancia su escena como una
capa modal al seleccionar **Recogida**. La habitación permanece cargada debajo,
pero el árbol queda pausado y el jugador se detiene; por eso cerrar el minijuego
restaura de forma natural la misma habitación, posición y estado.

`AnimalPickupBackdropCatalog` agrupa diez fondos de bosque y diez de ciudad. Al
instanciarse, el minijuego elige primero uno de los dos entornos y después una
entrada de su grupo. Cada `AnimalPickupBackdrop` asocia la textura con
`animal_hit_rect`, un rectángulo normalizado que identifica la posición real de
la silueta. El clic se transforma al rectángulo visible de la textura teniendo
en cuenta su ajuste de aspecto; solo un clic dentro de esa zona inicia la barra.
Cuando el futuro mapa exterior conozca el entorno, podrá sustituir la elección
aleatoria sin modificar el catálogo ni las hitboxes.

`AnimalPickupMinigame` es dueño de la presentación y de la futura lógica del
evento de tiempo rápido. `HitTimingBar` dibuja la barra, la zona válida y el
marcador. El clic correcto sobre el animal muestra la barra y comienza el
movimiento; después el marcador rebota entre ambos extremos. Al abrir el módulo, la zona válida recibe
una anchura aleatoria entre el 5% y el 35% de la barra. Cada intento se evalúa
mediante `is_marker_inside_target()`, emite `attempt_finished(success)` y se
reanuda tras un feedback breve.

El balance no se codifica en la escena: `AnimalPickupConfig` define su esquema y
`default_animal_pickup_config.tres` guarda velocidad, anchuras mínima y máxima de
la zona válida, posición inicial y duración del feedback. El centro se calcula
aleatoriamente en cada apertura dentro de los límites que mantienen la zona
completa en la barra. La escena recibe el recurso mediante su propiedad exportada
`config`, permitiendo crear variantes de dificultad sin duplicar lógica.

`n_replays_hit_timing_bar` define el número de aciertos necesarios para terminar
la sesión. Al alcanzarlo, el marcador se detiene, el resultado permanece visible
durante `completion_close_delay` y después se usa el mismo flujo de la señal
`closed`. El primer fallo continúa cerrando inmediatamente. Las consecuencias de
éxito y fallo quedan deliberadamente fuera del módulo por ahora.

El módulo se comunica con el juego principal mediante la señal `closed`; no
debe acceder a `ShelterRoom`, `PlayerController` ni a los datos internos de
`GameController`.

## Convención de nombres

Los nombres técnicos de archivos, escenas, recursos, nodos e IDs usan
`snake_case`. El idioma se elige según el vocabulario acordado por el equipo;
por ejemplo, `cat_siames` es un identificador técnico válido. Los nombres que
ve la persona jugadora se guardan por separado, por ejemplo
`nombre = "Siamés"`.
