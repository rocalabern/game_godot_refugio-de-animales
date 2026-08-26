# Prototipo de movimiento en grid y navegación nativa

- Cada habitación mide **20 x 12** casillas útiles.
- Hay una fila superior adicional reservada a menús; el área visible se divide en 21 columnas y 13 filas visuales. Los valores están expuestos en `Main`.
- El cuadrado azul ocupa **1 x 2** visualmente, pero solo su casilla inferior tiene hit box y afecta a navegación/colisiones; la parte superior puede pasar visualmente detrás de objetos para dar profundidad.
- La alfombra (`Rug`) usa tamaño configurable y `z_index = -1`, por lo que el personaje siempre se dibuja encima.
- La mesa ocupa 2 x 2, bloquea sus cuatro casillas y comparte el contenedor `WorldYSort` con el jugador. Godot decide correctamente qué objeto se muestra delante.
- El movimiento usa `NavigationRegion2D` y `NavigationAgent2D`. La cuadrícula no calcula rutas: genera el polígono navegable y las colisiones físicas de cada sala.
- Las casillas rojas son colisiones base. La mesa y futuros muebles se añaden como colisiones dinámicas antes de construir la navegación.
- La transición a `shelter_dogs` tiene una zona de puerta en la apertura de la pared de fondo (columnas 16 a 19). Solo se arma al clicar expresamente la pared/abertura y se activa cuando el punto de base —la única fila física del personaje— entra en ella.

## Pintar la colisión base dentro de Godot

1. Abre `rooms/shelter_entrada.tscn` o `rooms/shelter_dogs.tscn` en la vista **2D**.
2. Selecciona el nodo raíz `ShelterEntrada` o `ShelterDogs`.
3. Pulsa **Pintar colisiones** en la barra superior de la vista 2D.
4. Haz clic en una casilla para alternarla: rojo significa bloqueada y transparente significa caminable.
5. Guarda la escena. `Ctrl+Z` y `Ctrl+Y` deshacen o rehacen cada pincelada.

Las casillas se guardan en el recurso `RoomGridData` integrado en cada escena, no en un PNG. Estas son las colisiones base; la mesa y futuros muebles se suman como colisiones dinámicas.

## Animales

- `entities/animals/cat.tscn` es la escena base `Cat`: salud, hambre, energía, felicidad, comer, jugar, descansar e interacción táctil.
- `entities/animals/cat_siames.tscn` hereda de `Cat` y usa `assets/cat_siames.png`.
- Todos los gatos usan un aspecto visual de 1 columna x 2 filas; su origen y zona interactuable están en la base, para usar correctamente Y-Sort.
- Como prueba actual, se instancia un `CatSiames` en la casilla de base `(5, 8)` de `shelter_entrada`. Ocupa visualmente 1 columna x 2 filas, pero solo la fila inferior tiene colisión e impide el paso.
