# Historial de desarrollo

Este documento resume los principales pasos de desarrollo de **Refugio de
animales** a partir de las conversaciones asociadas al proyecto, el historial
de Git y el estado actual del repositorio.

## Estado actual

- Prototipo 2D desarrollado con Godot 4.7.
- Resolución lógica de 1008 × 624 píxeles, basada en una cuadrícula de 48 px,
  con escalado proporcional para escritorio, tablet y móvil.
- Entrada del refugio jugable, habitaciones para gatos, perros y aves, mapa
  exterior y minijuego de recogida de animales.
- Movimiento del personaje mediante clic o toque, navegación sobre cuadrícula,
  colisiones, ordenación por profundidad y transiciones entre escenas.
- Sistema común de animales con ficha, necesidades, personalidad e interacción
  de acariciar.

## 28 de agosto de 2026 — Mapa, minijuego y perros

### Minijuego de recogida

- Se creó un módulo independiente para la recogida de animales.
- Se añadieron escenarios aleatorios de bosque y ciudad, con diez variantes de
  fondo para cada entorno.
- El jugador debe localizar primero al animal oculto y pulsarlo para comenzar
  el evento de precisión.
- Se implementó una barra de tiempo con marcador rebotante y una zona de
  acierto verde de tamaño y posición variables.
- La sesión requiere tres aciertos consecutivos; un fallo la termina.
- Se centralizaron velocidad, dificultad, repeticiones y tiempos de respuesta
  en un recurso de configuración reutilizable.
- Se integraron la apertura, pausa, cierre y restauración del estado anterior
  del refugio o del mapa.

### Mapa exterior

- Se añadió un mapa navegable mediante clic o toque, con un avatar específico
  y movimiento limitado al área visible de la imagen.
- La puerta izquierda de la entrada conecta el refugio con el mapa y conserva
  un punto de aparición definido al regresar.
- Se implementaron encuentros aleatorios mediante marcadores temporales y
  pulsantes que abren el minijuego.
- Una victoria devuelve automáticamente al jugador a la entrada; un fallo
  permite continuar explorando.
- Los parámetros de movimiento y aparición de encuentros se trasladaron a una
  configuración editable.

### Perros y rescates

- Se creó la clase común `Dog`, heredada del sistema general de animales.
- Se añadieron cuatro razas con escena y textura propias: beagle, pastor alemán,
  husky y caniche.
- Los perros reutilizan la ficha, las necesidades, la personalidad y la acción
  de acariciar ya disponibles para los gatos.
- Cada victoria en el minijuego registra un perro rescatado de raza aleatoria y
  le asigna un nombre escogido de un catálogo de 16 posibilidades.
- Los perros rescatados aparecen en casillas disponibles de la entrada y
  conservan su identidad y estado al cambiar de habitación durante la partida.
- Se verificó mediante una prueba de integración la creación de un perro con
  nombre y raza válidos.

### Plataforma y presentación

- Se añadió una configuración de exportación para Android.
- Se incorporaron imágenes de muestra a la documentación del proyecto.
- Se ajustaron la resolución lógica, el escalado y el tratamiento de texturas
  para mejorar la presentación sin rehacer los recursos existentes.

## 27 de agosto de 2026 — Refugio, animales e interfaz

- Se rediseñó y refinó la entrada del refugio.
- Se añadieron las habitaciones de gatos, perros y aves.
- Se mejoró el menú principal y su integración con las escenas jugables.
- Se implementó la ficha modal de los animales con identidad, raza, edad,
  necesidades y rasgos de personalidad.
- Se añadió la interacción de acariciar: aparece al acercarse al animal, ejecuta
  una animación de respuesta y modifica sus indicadores de bienestar.
- Se mejoró la mecánica de cuidado y la persistencia de los datos del animal.
- El personaje dejó de representarse como una forma provisional y pasó a usar
  su textura definitiva.
- Se incorporaron recursos visuales y capturas para documentar el estado del
  juego.

## 26 de agosto de 2026 — Prototipo y arquitectura base

- Se creó el proyecto inicial y una escena jugable mínima.
- El primer personaje era un cuadrado controlado con las flechas del teclado.
- El control se cambió posteriormente a movimiento hacia el punto pulsado con
  el ratón, base del control actual compatible con toque.
- Se realizaron las primeras pruebas de habitación, fondo y colisiones.
- Se refactorizó el proyecto alrededor de componentes reutilizables:
  `PlaceableObject`, `AnimalObject`, `RoomData`, `RoomController` y
  `RoomOccupancy`.
- Se implantó una cuadrícula para colocación, ocupación y navegación, separando
  la huella visual, las casillas bloqueadas y las zonas de interacción.
- Se creó el sistema de habitaciones mediante capas de `TileMapLayer` para
  suelo, paredes y elementos de primer plano.
- Se añadieron colisiones a las paredes y navegación reconstruida a partir del
  mapa y de los objetos colocados.
- Se implementaron puertas configurables y transiciones entre habitaciones con
  puntos de aparición explícitos.
- Se ajustaron el tamaño de paredes y el diseño visual de las primeras salas.
- Se documentó la arquitectura y el flujo para añadir objetos, animales,
  habitaciones y puertas.

## 29 de agosto de 2026 — Nuevas razas y jerarquía de animales

- Se limitaron los tipos principales a `Cat`, `Dog` y `Bird`; se retiraron
  `Rabbit` y el tipo separado `Owl`, ya que los búhos son razas de ave.
- Se extrajo el comportamiento común a `PettableAnimal` para evitar duplicar
  escalado, física, navegación e interacción entre especies.
- Se añadieron las escenas de gato bengalí, british shorthair y persa.
- Se creó el tipo `Bird` y las escenas de periquito verde, periquito blanco,
  gran búho cornudo y búho chillón.
- Se añadieron `visual_columns` y `base_columns`: el ancho visible controla una
  escala uniforme y la altura se deriva del aspect ratio del PNG.
- Husky y pastor alemán pasaron a ocupar dos columnas de base; los otros diez
  animales mantienen una.
- El rescate dejó de estar limitado a perros y ahora selecciona cualquiera de
  las doce escenas de gato, perro o ave.
- La asignación de casillas de rescate reserva el ancho completo de la base para
  impedir solapamientos.
