# Minijuego «Curar»

## Objetivo

Añadir un minijuego aislado de búsqueda visual accesible desde **Menú del refugio → Curar**. Una sesión contiene tres rondas. En cada ronda aparece una mesa nueva de objetos de tamaño comparable y el jugador debe localizar el único objeto médico indicado en el visor circular inferior.

## Plan de desarrollo

1. **Integración mínima con el juego.** Añadir el botón `Curar` a `game/main.tscn`; el `GameController` instancia el minijuego como `CanvasLayer`, pausa el refugio y lo elimina al recibir `closed`. No se modifica el estado de animales ni de habitaciones.
2. **Catálogo extensible de recursos.** Crear `assets/minigames/cure/medical/` y `assets/minigames/cure/distractors/`. `cure_minigame.gd` recorre ambos directorios con `DirAccess`, carga todos los PNG y no mantiene una lista cerrada en código. Por ello un PNG nuevo será candidato automáticamente tras importarlo con Godot.
3. **Creatividades.** Crear objetos aislados con fondo transparente, aspecto cartoon/chibi, colores vivos y contorno fino del mismo color oscurecido. Mantener 256×256 px por archivo y margen transparente para que todos tengan una escala visual parecida.
4. **Generación de rondas.** Barajar el catálogo médico sin repetición para elegir tres objetivos distintos. Cada ronda genera una cuadrícula con exactamente una copia del objetivo y múltiples distractores; los distractores sí pueden repetirse. Se mezclan posiciones, pequeñas rotaciones y escalas controladas.
5. **Interacción y reglas.** Cada botón-objeto acepta un solo clic. El objetivo muestra `¡Lo encontraste!` en verde. Cualquier otro objeto muestra `¡Este no es!` en rojo y consume una de las tres vidas. Después de una pausa comienza la ronda siguiente con objetivo y mesa renovados.
6. **Cierre de sesión.** Tras la tercera ronda se muestra un resumen con aciertos y vidas restantes, y botones para repetir o volver. La X y `Esc` vuelven inmediatamente al refugio y restauran la pausa global.
7. **Verificación.** Validar carga dinámica, unicidad del objetivo, tres rondas, descuento de vida, bloqueo del doble clic, reinicio, cierre y funcionamiento con resolución base 1008×624.

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

### Objetos cotidianos (`assets/minigames/cure/distractors`)

- Parecidos intencionadamente: `jump_rope.png` (estetoscopio), `candy.png` (cápsula), `pocket_mirror.png` (espejo frontal), `ice_pop_stick.png` (depresor), `pen.png` (termómetro), `water_pistol.png` (jeringa), `rolled_sock.png` (venda) y `flashlight.png` (otoscopio).
- Variedad adicional: `ball.png`, `spoon.png`, `ruler.png`, `clothespin.png`, `paper_clips.png`, `pencil.png`, `calculator.png` y `comb.png`.

## Estructura del código

- `minigames/cure/cure_minigame.tscn`: capa visual, HUD, mesa, visor del objetivo y panel final.
- `minigames/cure/cure_minigame.gd`: descubrimiento de PNG, estado de sesión, generación y evaluación de rondas.
- `game/game_controller.gd`: abre y cierra la escena aislada.
- `game/main.tscn`: opción `Curar` del menú.
- `tools/slice_cure_item_sheets.py`: utilidad reproducible usada para separar hojas de creatividad en archivos 256×256.

Los nombres de archivo solo sirven como identificadores; no es necesario editar código al añadir recursos. Conviene conservar PNG cuadrados con transparencia y un único objeto centrado.
