# Minijuego «Curar»

## Objetivo

Añadir un minijuego aislado de búsqueda visual accesible desde **Menú del refugio → Curar**. Una sesión contiene tres rondas. En cada ronda aparece una mesa nueva de objetos de tamaño comparable y el jugador debe localizar el único objeto médico indicado en el visor circular inferior.

## Plan de desarrollo

1. **Integración mínima con el juego.** Añadir el botón `Curar` a `game/main.tscn`; el `GameController` instancia el minijuego como `CanvasLayer`, pausa el refugio y lo elimina al recibir `closed`. No se modifica el estado de animales ni de habitaciones.
2. **Catálogo extensible de recursos.** Crear `assets/minigames/cure/medical/` y `assets/minigames/cure/distractors/`. `cure_minigame.gd` recorre ambos directorios con `DirAccess`, carga todos los PNG y no mantiene una lista cerrada en código. Por ello un PNG nuevo será candidato automáticamente tras importarlo con Godot.
3. **Creatividades.** Crear objetos aislados con fondo transparente, aspecto cartoon/chibi, colores vivos y contorno fino del mismo color oscurecido. Mantener 256×256 px por archivo y margen transparente para que todos tengan una escala visual parecida.
	La utilidad de recorte elimina automáticamente islas de píxeles diminutas y desconectadas del dibujo principal para evitar fragmentos visuales alrededor de los objetos.
4. **Generación de rondas.** Barajar el catálogo médico sin repetición para elegir tres objetivos distintos. Cada ronda genera una mesa libre con exactamente una copia del objetivo y 47 distractores; los distractores sí pueden repetirse. Un algoritmo prueba posiciones aleatorias y minimiza el área compartida, permitiendo solapamientos pequeños. Se mezclan orden de profundidad, posiciones, rotaciones y escalas.
5. **Interacción y reglas.** Cada botón-objeto acepta un solo clic. El objetivo muestra `¡Lo encontraste!` en verde. Cualquier otro objeto muestra `¡Este no es!` en rojo y consume una de las tres vidas. Después de una pausa comienza la ronda siguiente con objetivo y mesa renovados.
6. **Cierre de sesión.** Tras la tercera ronda se muestra un resumen con aciertos y vidas restantes, y botones para repetir o volver. La X y `Esc` vuelven inmediatamente al refugio y restauran la pausa global.
7. **Verificación.** Validar carga dinámica, unicidad del objetivo, tres rondas, descuento de vida, bloqueo del doble clic, reinicio, cierre y funcionamiento con resolución base 1008×624.

La primera ronda espera a que los contenedores de Godot hayan calculado el tamaño real de la mesa. Esto evita generar todas las posiciones en `(0, 0)` durante el primer frame de una partida recién iniciada.

## Inventario de imágenes

### Medicina veterinaria (`assets/minigames/cure/medical`)

- `stethoscope.png`: estetoscopio.
- `capsule.png`: cápsula roja y blanca.
- `head_mirror.png`: espejo frontal médico con banda.
- `tongue_depressor.png`: depresor lingual de madera.
- `thermometer.png`: termómetro digital.
- `syringe.png`: jeringa amigable.
- `bandage_roll.png`: venda enrollada.
- `otoscope.png`: otoscopio.
- `reflex_hammer.png`: martillo de reflejos veterinario.
- `medicine_dropper.png`: frasco cuentagotas de medicación.
- `cone_collar.png`: collar isabelino.
- `medical_tweezers.png`: pinzas médicas.

### Objetos cotidianos (`assets/minigames/cure/distractors`)

- Parecidos intencionadamente: `jump_rope.png` (estetoscopio), `candy.png` (cápsula), `pocket_mirror.png` (espejo frontal), `ice_pop_stick.png` (depresor), `pen.png` (termómetro), `water_pistol.png` (jeringa), `rolled_sock.png` (venda) y `flashlight.png` (otoscopio).
- Variedad adicional: `ball.png`, `spoon.png`, `ruler.png`, `clothespin.png`, `paper_clips.png`, `pencil.png`, `calculator.png` y `comb.png`.
- Nuevos parecidos: `toy_mallet.png` (martillo de reflejos), `glue_bottle.png` (cuentagotas), `party_hat.png` (collar isabelino) y `kitchen_tongs.png` (pinzas médicas).
- Nueva variedad: `keyring.png`, `wristwatch.png`, `toy_car.png`, `rubber_duck.png`, `mug.png`, `mitten.png`, `banana.png`, `padlock.png`, `paint_brush.png`, `magnifying_glass.png`, `bell.png` y `cassette_tape.png`.

## Estructura del código

- `minigames/cure/cure_minigame.tscn`: capa visual, HUD, mesa, visor del objetivo y panel final.
- `minigames/cure/cure_minigame.gd`: descubrimiento de PNG, estado de sesión, generación y evaluación de rondas.
- `minigames/cure/cure_minigame_config.gd`: definición tipada de todos los parámetros configurables.
- `minigames/cure/default_cure_minigame_config.tres`: valores utilizados por defecto (`partidas_seguidas = 3`, `vidas = 3`, cantidad y tamaño de objetos, distribución, interacción y catálogos).
- `game/game_controller.gd`: abre y cierra la escena aislada.
- `game/main.tscn`: opción `Curar` del menú.
- `tools/slice_cure_item_sheets.py`: utilidad reproducible usada para separar hojas de creatividad en archivos 256×256.

Los nombres de archivo solo sirven como identificadores; no es necesario editar código al añadir recursos. Conviene conservar PNG cuadrados con transparencia y un único objeto centrado.

## Configuración

El recurso `default_cure_minigame_config.tres` puede editarse directamente desde el inspector de Godot. Agrupa:

- **Partida:** `partidas_seguidas`, `vidas`, `objetos_en_pantalla` y `espera_resultado`.
- **Distribución:** `tamano_objeto`, intentos de colocación, rotaciones, escalas y profundidad.
- **Interacción:** umbral alfa de clic y frames máximos para resolver el layout inicial.
- **Catálogos:** carpetas de medicina y distractores.

La escena recibe este recurso mediante la propiedad exportada `config`, por lo que también se pueden crear configuraciones alternativas sin modificar `cure_minigame.gd`.
