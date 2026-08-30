# Cura v2 · Mastermind veterinario

## Objetivo

Crear un minijuego modal e independiente basado en Mastermind. El jugador debe descubrir una receta secreta de cápsulas de colores. Cada intento recibe dos tipos de pista: un hueso dorado por cada color en la posición correcta y un hueso plateado por cada color correcto colocado en otra posición.

## Plan de desarrollo

1. **Integración aislada.** Añadir `Cura v2` al menú hamburguesa. `GameController` instancia el minijuego sobre el refugio, detiene al personaje, pausa el árbol y elimina la escena cuando emite `closed`.
2. **Creatividades consistentes.** Crear una cápsula cartoon/chibi con fondo transparente y producir seis variantes geométricamente idénticas: rojo, amarillo, azul, lila, naranja y rosa. Crear también un hueso dorado y uno plateado para las pistas.
3. **Configuración separada.** Definir `MastermindRoundConfig` para una partida (`posiciones`, `cantidad_colores`, `intentos_maximos` y repetición) y `MastermindConfig` para la sesión completa, tiempos y recursos visuales. Mantener los valores en `default_mastermind_config.tres`.
4. **Tres partidas configurables.** Configuración predeterminada: partida 1 con 3 posiciones/3 colores; partida 2 con 5 posiciones/4 colores; partida 3 con 6 posiciones/6 colores. Cada partida genera un código secreto nuevo.
5. **Entrada del jugador.** Mostrar una paleta con los colores habilitados. Pulsar una cápsula llena la siguiente posición. Cada posición puede vaciarse pulsándola; `Borrar` limpia la propuesta y `Comprobar` solo se habilita cuando está completa.
6. **Evaluación Mastermind.** Primero contar coincidencias exactas y excluirlas. Después cruzar las frecuencias restantes para contar colores correctos en posición incorrecta, sin duplicar pistas. El orden de los huesos no revela qué posición produjo cada pista.
7. **Historial y progreso.** Añadir cada intento a un historial desplazable con las cápsulas propuestas y sus huesos. Limitar intentos por configuración. Al acertar o agotarlos, mostrar el resultado y avanzar a la siguiente partida tras una pausa.
8. **Final y reinicio.** Tras tres partidas, mostrar cuántas recetas se resolvieron, con botones para repetir toda la sesión o volver al refugio. La X y `Esc` cierran inmediatamente.
9. **Verificación.** Probar los límites de 3–6 posiciones y 2–6 colores, códigos repetidos, conteo de duplicados, cambio de configuración entre partidas, victoria, agotamiento de intentos, reinicio y cierre modal.

## Estructura de archivos

```text
minigames/cure_mastermind/
├── cure_mastermind_minigame.gd
├── cure_mastermind_minigame.tscn
├── mastermind_config.gd
├── mastermind_round_config.gd
└── default_mastermind_config.tres

assets/minigames/cure_mastermind/
├── capsules/
│   ├── red.png
│   ├── yellow.png
│   ├── blue.png
│   ├── lilac.png
│   ├── orange.png
│   └── pink.png
└── feedback/
    ├── golden_bone.png
    └── silver_bone.png
```

## Estructura de objetos

- `CureMastermindMinigame` (`CanvasLayer`): controla sesión, partida, secreto, intento actual e historial.
- `MastermindConfig` (`Resource`): contiene las tres configuraciones de partida, las seis texturas y los iconos de pista.
- `MastermindRoundConfig` (`Resource`): parámetros independientes de una partida.
- `GameController`: única integración con el juego principal; abre y cierra el modal.

Las cápsulas se almacenan en el orden rojo, amarillo, azul, lila, naranja y rosa. `cantidad_colores` toma los primeros N colores de este catálogo, por lo que cualquier partida puede limitarse de 2 a 6 colores sin tocar código.
