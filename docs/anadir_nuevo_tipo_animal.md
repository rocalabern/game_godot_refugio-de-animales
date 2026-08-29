# Guía para añadir un nuevo tipo de animal

Esta guía describe el proceso completo para incorporar una especie nueva al
proyecto, por ejemplo `Ferret` (hurón), y después crear una o más razas de esa
especie. Está basada en la arquitectura actual de gatos, perros y aves.

> En este proyecto, **tipo** significa especie (`Cat`, `Dog`, `Bird`) y
> **raza** significa una variante concreta (`Siames`, `Beagle`, etc.). Añadir
> solo una raza nueva es bastante más sencillo que añadir un tipo nuevo.

## 1. Entender la jerarquía existente

La programación orientada a objetos se reparte en cuatro niveles:

```text
PlaceableObject                    Contrato de objeto colocado en una sala
└── AnimalObject                   Identidad, necesidades y personalidad
    └── PettableAnimal             Física, visual y acción de acariciar
        ├── Cat                    Tipo concreto: gato
        │   └── escenas de raza    Identidad y textura
        ├── Dog                    Tipo concreto: perro
        │   └── escenas de raza    Identidad y textura
        ├── Bird                   Tipo concreto: ave, incluidos los búhos
        │   └── escenas de raza    Identidad y textura
        └── NuevaEspecie           Nuevo tipo concreto
            └── escenas de raza
```

Los archivos relevantes son:

- `entities/shared/placeable_object.gd`: huella, bloqueo, interacción y
  ordenación por Y de cualquier objeto.
- `entities/animals/animal_object.gd`: datos comunes de todos los animales.
- `entities/animals/pettable_animal.gd` y `.tscn`: comportamiento y nodos
  compartidos por los animales que pueden acariciarse.
- `entities/animals/cats`, `dogs` y `birds`: clases concretas y escenas de raza.
- `ui/animal_profile/animal_profile.gd`: ficha genérica; funciona con cualquier
  `AnimalObject` y obtiene el retrato del nodo `Visual`.
- `systems/placement/placed_object_data.gd`: referencia una escena de objeto y
  la casilla donde se coloca.
- `rooms/shared/room_controller.gd`: instancia los objetos, conecta su
  interacción y conserva el estado de los animales.
- `game/game_controller.gd`: estado de partida y sistema de perros rescatados.

La habitación no debe preguntar si un objeto es un gato, perro o ave. Solo debe
verlo como `AnimalObject`. Los búhos son aves: `great_horned_owl` y
`screech_owl` tienen `tipo = "Bird"`; sus nombres concretos se guardan en
`raza`. La lógica común está en `AnimalObject` y `PettableAnimal`; la clase de
especie solo contiene aquello que sea realmente específico de ese tipo.

## 2. Decidir si se añade una raza o una especie

### Si solo se añade una raza existente

Por ejemplo, un labrador pertenece al tipo `Dog`. No hace falta crear otro
script ni duplicar `dog.tscn`. Basta con:

1. preparar su PNG;
2. añadir el valor de raza al enum de `AnimalObject`;
3. crear una escena heredada de `dog.tscn`;
4. asignar textura, raza, edad y nombre;
5. colocarla en una sala o registrarla como posible rescate.

### Si se añade una especie nueva

Por ejemplo, un hurón necesitaría:

1. ampliar los tipos y razas admitidos por `AnimalObject`;
2. crear `ferret.gd` y `ferret.tscn` heredando de la base compartida;
3. crear al menos una escena de raza heredada de `ferret.tscn`;
4. colocarla en una sala;
5. opcionalmente, integrarla en el sistema de rescates.

### Catálogo implementado actualmente

| Tipo/clase | Escenas de raza disponibles |
|---|---|
| `Cat` | `cat_siames`, `bengal`, `british_shorthair`, `persian` |
| `Dog` | `beagle`, `german_sheperd`, `huskie`, `poodle` |
| `Bird` | `budgie_green`, `budgie_white`, `great_horned_owl`, `screech_owl` |

No existe un tipo `Rabbit`. Tampoco existe una clase principal `Owl`: un búho
es un `Bird` cuya escena de raza aporta su identidad y creatividad.

## 3. Preparar las creatividades

### 3.1. Estructura de carpetas

Usar una carpeta por especie y otra por raza:

```text
assets/animals/ferrets/
└── sable/
    └── sable.png

entities/animals/ferrets/
├── ferret.gd
├── ferret.tscn
└── sable.tscn
```

Los identificadores técnicos deben usar `snake_case`, sin espacios ni tildes.
Los textos visibles sí pueden escribirse correctamente en español:

```text
Archivo: sable.tscn
Nodo:   FerretSable
Raza:   "Sable"
```

### 3.2. Requisitos recomendados para el PNG

- Fondo transparente real, no blanco ni cuadriculado.
- Un solo animal por imagen.
- Animal de cuerpo entero y con las patas visibles.
- Vista coherente con las ilustraciones existentes.
- Iluminación, contorno, saturación y nivel de detalle similares al resto.
- Espacio transparente moderado; evitar lienzos mucho mayores que el dibujo.
- La base de las patas debe marcar claramente el punto de apoyo.
- No incluir nombre, marco, sombra de interfaz ni fondo dentro del PNG.
- Mantener una resolución fuente suficiente. El juego la reduce al tamaño de
  cuadrícula, por lo que una fuente grande y limpia evita degradación.

Gatos, perros y aves se representan actualmente en una columna por dos filas de
48 px. Solo la casilla inferior bloquea el paso. Si la nueva especie tiene un
tamaño parecido, se recomienda conservar este contrato visual. Si ocupa más
espacio, habrá que adaptar explícitamente `footprint`, `get_visual_cells()`, las
colisiones y el escalado.

### 3.3. Importación en Godot

1. Copiar el PNG dentro de `assets/animals/...`.
2. Volver al editor y esperar a que Godot genere su importación.
3. Seleccionar la textura y revisar que conserve el canal alfa.
4. Para un estilo pixel art, usar filtro `Nearest`; para ilustración suave,
   usar filtrado lineal. No mezclar criterios entre animales equivalentes.
5. Comprobar la imagen a la resolución lógica del juego, no solo ampliada en el
   editor.

No se debe versionar una creatividad sin su escena consumidora, salvo que esté
marcada expresamente como recurso pendiente.

## 4. Registrar el tipo y sus razas en `AnimalObject`

Abrir `entities/animals/animal_object.gd`.

### 4.1. Añadir la especie al enum

La propiedad actual es:

```gdscript
@export_enum("Cat", "Dog", "Bird") var tipo := "Cat"
```

Para otra especie, por ejemplo `Ferret`, se debe añadir al enum:

```gdscript
@export_enum("Cat", "Dog", "Bird", "Ferret") var tipo := "Cat"
```

Estos valores son identificadores internos estables. Evitar traducirlos o
cambiarlos después de haber creado escenas que los utilicen.

### 4.2. Añadir las razas al enum

Incorporar cada raza nueva a `raza`:

```gdscript
@export_enum(
    "Siames",
    "Bengalí",
    "British Shorthair",
    "Persa",
    "Beagle",
    "Pastor alemán",
    "Husky",
    "Caniche",
    "Periquito verde",
    "Periquito blanco",
    "Gran búho cornudo",
    "Búho chillón",
    "Sable"
) var raza := "Siames"
```

El enum solo ayuda a editar desde el Inspector; el valor sigue siendo un
`String`. El texto debe coincidir exactamente con el que se asignará en la
escena de raza.

Si el número de especies y razas crece mucho, convendrá sustituir este enum
global por recursos de definición de especie/raza. Por ahora se debe seguir la
convención existente para mantener el proyecto homogéneo.

### 4.3. Añadir el nombre visible de la especie

Ampliar `get_tipo_display_name()`:

```gdscript
func get_tipo_display_name() -> String:
    match tipo:
        "Cat": return "Gato"
        "Dog": return "Perro"
        "Bird": return "Ave"
        "Ferret": return "Hurón"
        _: return tipo
```

Este método alimenta la ficha y la descripción de personalidad. Si se omite,
la interfaz mostrará el identificador técnico.

## 5. Crear la clase de la especie

Crear, por ejemplo, `entities/animals/ferrets/ferret.gd`. Para una especie con
el mismo contrato visual y de cuidado, la clase es deliberadamente mínima:

```gdscript
class_name Ferret
extends PettableAnimal

## Tipo concreto para todas las razas de hurón.
```

`PettableAnimal` ya aporta configuración de cuadrícula, ancho visual y físico
configurables, escalado uniforme, alineación por la última fila opaca, cercanía
del jugador, ratón, toque, modo de edición, icono de mano y animación de
acariciar. La clase concreta solo debe sobrescribir lo que sea distinto en esa
especie.

La señal `selected` existe en `PettableAnimal`, pero la apertura de la
ficha no depende de ella: `InteractionController` identifica la casilla visual,
llama al método genérico `interact()` de `PlaceableObject` y `RoomController`
emite después `animal_interaction_requested`. No se debe conectar la ficha
directamente desde la clase de especie.

### Evitar duplicación

No copiar el contenido de `pettable_animal.gd` dentro de `Cat`, `Dog`, `Bird` o
una especie futura. Si una regla es común, debe cambiarse una sola vez en la
base. Si únicamente una especie necesita otra huella o reacción, esa clase puede
sobrescribir el método concreto y llamar a `super` cuando corresponda.

## 6. Definir huella, colisión y tamaño visual

Cada escena de raza configura dos propiedades independientes:

```gdscript
@export_range(1, 4, 1) var visual_columns := 1
@export_range(1, 4, 1) var base_columns := 1
```

`visual_columns` controla exclusivamente el ancho visible. `base_columns`
controla cuántas casillas inferiores tienen colisión y bloquean navegación. La
altura visual no se introduce manualmente: se calcula desde el aspect ratio de
la parte opaca del PNG.

```gdscript
var used_rect := visual.texture.get_image().get_used_rect()
var target_width := visual_columns * cell_size.x
var scale_factor := target_width / float(used_rect.size.x)
visual.scale = Vector2.ONE * scale_factor
visual_rows = ceili(used_rect.size.y * scale_factor / cell_size.y)
```

La misma escala se aplica a X e Y, por lo que la creatividad nunca se deforma.
Se utiliza `get_used_rect()` para ignorar márgenes transparentes al calcular el
ancho y para apoyar la última fila opaca sobre la base.

La colisión física ocupa una fila y tantas columnas como `base_columns`:

```gdscript
shape.size = Vector2(cell_size.x * base_columns, cell_size.y)
```

Configuración actual:

| Razas | `visual_columns` | `base_columns` |
|---|---:|---:|
| Husky y pastor alemán | 2 | 2 |
| Los otros diez animales | 1 | 1 |

`base_cell` representa la casilla inferior izquierda. El nodo se centra sobre
todo el ancho mediante `get_cell_anchor_offset()`. Las casillas visuales se
generan con el ancho configurado y las filas calculadas; las casillas bloqueadas
son únicamente las de la fila inferior.

Si una especie necesita una forma distinta, revisar también:

- tamaño de la colisión física;
- casillas visuales relativas;
- casillas que bloquean navegación;
- posición del icono de acción;
- distancia de cuidado;
- casillas disponibles en la sala;
- retrato en la ficha.

## 7. Crear la escena base de la especie

Crear `entities/animals/ferrets/ferret.tscn` como escena heredada de
`pettable_animal.tscn` y asignarle el script concreto:

```gdscript
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene"
path="res://entities/animals/pettable_animal.tscn" id="1_pettable"]
[ext_resource type="Script"
path="res://entities/animals/ferrets/ferret.gd" id="2_ferret"]

[node name="Ferret" instance=ExtResource("1_pettable")]
script = ExtResource("2_ferret")
tipo = "Ferret"
```

La escena compartida ya contiene `Visual`, `InteractionArea`, `Body` y
`HandAction`. No duplicar esos nodos. La escena de especie aporta el script y el
valor `tipo`; la escena de raza aportará la textura y sus datos.

## 8. Crear una escena por raza

La escena de raza hereda de la escena base y solo aporta datos y creatividad.
Ejemplo conceptual para `sable.tscn`:

```gdscript
[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene"
path="res://entities/animals/ferrets/ferret.tscn" id="1_ferret"]
[ext_resource type="Texture2D"
path="res://assets/animals/ferrets/sable/sable.png"
id="2_texture"]

[node name="FerretSable" instance=ExtResource("1_ferret")]
raza = "Sable"
edad = 2
nombre = "Sable"

[node name="Visual" parent="." index="0"]
texture = ExtResource("2_texture")
```

Significado de los campos:

- `tipo`: lo hereda de `ferret.tscn`; no repetirlo en cada raza.
- `raza`: valor visible y persistente de la raza.
- `edad`: valor inicial para ejemplares colocados manualmente.
- `nombre`: nombre descriptivo de respaldo.
- `pet_name`: nombre individual; si está vacío, la ficha muestra `nombre`.

No duplicar la jerarquía de nodos en cada raza. La herencia de escena permite
que cualquier arreglo en `ferret.tscn` alcance automáticamente a todas ellas.

## 9. Configurar identidad, necesidades y personalidad

Todos estos campos ya existen en `AnimalObject` y aparecen en el Inspector.

### Identidad

- `tipo`: especie técnica.
- `raza`: raza visible.
- `edad`: entero entre 0 y 100.
- `nombre`: descripción o nombre por defecto.
- `pet_name`: nombre individual mostrado como título de la ficha.

### Necesidades

- `salud`: 0–100; más alto es mejor.
- `hambre`: 0–100; más bajo es mejor.
- `higiene`: 0–100; más alto es mejor.
- `felicidad`: 0–100; más alto es mejor.
- `energia`: 0–100; más alto es mejor.

Al entrar por primera vez en una partida, `initialize_runtime_state()` reemplaza
salud, hambre, higiene, energía y personalidad por valores aleatorios, y fija
felicidad en 15. El `GameController` conserva después esos datos en
`animal_states` usando sala y nombre de nodo como clave.

Si se añade un nuevo dato persistente, hay que modificar conjuntamente:

1. la propiedad exportada;
2. `initialize_runtime_state()`;
3. `get_runtime_state()`;
4. `apply_runtime_state()`;
5. la ficha, si debe mostrarse.

### Personalidad

Las cuatro características actuales son activo, sociable, dependiente y
adiestramiento. Sus valores van de 0 a 100 y generan una descripción textual.
La especie se inserta automáticamente mediante `get_tipo_display_name()`.

### Acción de acariciar

En el código actual, `receive_care(15.0)` aumenta **solo la felicidad** y la
limita a 100. `feed()`, `play()` y `clean()` modifican otras necesidades, pero
todavía no tienen botones en la ficha. Si una especie reacciona de manera
diferente, puede sobrescribir `receive_care()` sin modificar la habitación ni
la interfaz.

## 10. Listados de nombres

Actualmente el catálogo está codificado en `game/game_controller.gd` como
`ANIMAL_NAMES` y se utiliza para gatos, perros y aves rescatados:

```gdscript
const ANIMAL_NAMES: Array[String] = [
    "Luna", "Toby", "Nala", "Max", "Kira", "Bruno", "Milo", "Coco",
    "Lola", "Rocky", "Bimba", "Leo", "Duna", "Simba", "Noa", "Otto",
]
```

Para animales colocados manualmente se puede establecer `pet_name` directamente
en su escena o en tiempo de ejecución.

Si una especie futura necesita nombres específicos, hay dos opciones:

### Opción mínima

Crear otro catálogo, por ejemplo `FERRET_NAMES`, y seleccionar el adecuado en
el método que registre ese rescate.

### Opción recomendada si habrá varias especies

Reemplazar las constantes específicas por catálogos indexados por tipo:

```gdscript
const ANIMAL_NAMES := {
    "Dog": ["Luna", "Toby", "Nala"],
    "Ferret": ["Mochi", "Nube", "Canela"],
}
```

La escena seleccionada ya conoce su `tipo` y `raza`; no se debe guardar una raza
separada que pueda contradecir a la escena. El nombre elegido debe guardarse en
`pet_name` para que la ficha lo use como título.

Conviene que los catálogos:

- no estén vacíos;
- eviten duplicados involuntarios;
- usen textos visibles, con tildes si corresponden;
- sean suficientemente amplios para reducir repeticiones;
- permitan nombres neutros salvo que el diseño introduzca sexo explícito.

## 11. Colocar el animal en una habitación

Los animales fijos se añaden al `RoomData` de la escena mediante un
`PlacedObjectData`. Puede hacerse desde el Inspector o declarando el subrecurso
en el `.tscn`.

Ejemplo:

```gdscript
[ext_resource type="PackedScene"
path="res://entities/animals/ferrets/sable.tscn"
id="8_ferret"]

[sub_resource type="Resource" id="PlacedFerretSable"]
script = ExtResource("4_placement")
id = "Ferret_Sable_01"
scene = ExtResource("8_ferret")
base_cell = Vector2i(8, 8)
```

Añadir después el subrecurso al array `placements` del `RoomData`.

Cada colocación necesita:

- `id` único y estable dentro de la sala;
- `scene` apuntando a la escena concreta de raza;
- `base_cell` transitable y con espacio visual suficiente.

El ID acaba siendo el nombre del nodo y participa en la clave de persistencia.
Cambiarlo puede hacer que el animal reciba un estado nuevo en vez de restaurar
el anterior.

No hay que añadir manualmente navegación. `RoomController` instancia el animal,
configura la cuadrícula, conecta la interacción y reconstruye la ocupación.

## 12. Integrarlo en la ficha

Normalmente no hay que modificar `AnimalProfile`. La ficha funciona con el
contrato `AnimalObject` y muestra:

- `pet_name` o, si está vacío, `nombre`;
- tipo traducido por `get_tipo_display_name()`;
- raza y edad;
- descripción de personalidad;
- barras de necesidades;
- textura del hijo `Visual` como retrato.

La integración será automática si:

1. la escena hereda directa o indirectamente de `AnimalObject`;
2. el nodo del sprite se llama exactamente `Visual`;
3. conserva `is_interactable = true` y declara correctamente sus casillas
   visuales mediante `get_visual_cells()`;
4. la sala administra el animal como parte de sus objetos y conecta la señal
   genérica `interacted`.

El clic sobre la ficha se resuelve por la cuadrícula, no por la señal `selected`
del `InteractionArea`. El área se conserva porque forma parte de las escenas
actuales y puede servir para interacción directa futura; la acción de la mano sí
usa su propia `Area2D` y su evento de entrada.

Si el retrato queda demasiado pequeño por el espacio transparente del PNG, se
debe corregir la creatividad o mejorar el encuadre de `set_portrait()`; no
alterar la colisión para compensarlo.

## 13. Integrarlo en el sistema de rescates (opcional)

El sistema trabaja de forma genérica con las doce escenas registradas en
`RESCUABLE_ANIMAL_SCENES`. Para que una raza nueva pueda aparecer tras superar
el minijuego, hay que añadir allí su `PackedScene`.

```gdscript
var rescued_animals: Array[Dictionary] = []
```

Cada entrada debería conservar como mínimo:

```gdscript
{
    "id": "RescuedAnimal_001",
    "scene": packed_scene_de_raza,
    "pet_name": "Mochi",
    "base_cell": Vector2i(8, 9),
    "base_columns": 1,
}
```

`_register_rescued_animal()` elige una escena aleatoria, lee su
`base_columns`, reserva todas las casillas inferiores y asigna un nombre.
`_restore_rescued_animals_in_current_room()` trabaja siempre con
`AnimalObject`. Al restaurar:

1. comprobar que la sala destino es la correcta;
2. evitar duplicar un nodo con el mismo ID;
3. llamar a `add_runtime_animal()`;
4. asignar `pet_name`;
5. recuperar o inicializar el estado;
6. guardarlo en `animal_states`;
7. reconstruir navegación, ya realizado por la sala.

También se deben revisar las casillas de aparición cuando crezca el catálogo.
La reserva actual comprueba una o dos columnas según `base_columns`; si se
admiten animales todavía mayores habrá que asegurar suficientes posiciones
válidas en la entrada.

## 14. Comprobaciones en el editor

Abrir la escena de raza directamente y comprobar:

- no hay recursos externos rotos;
- el script reconoce el tipo y la raza;
- el PNG aparece con transparencia;
- el animal mantiene su proporción;
- las patas coinciden con el origen/base;
- `InteractionArea` cubre todo el ancho de la base;
- el cuerpo físico cubre la fila de base, no todo el dibujo;
- el icono de mano aparece encima del animal;
- no hay avisos de nodos inexistentes en los `@onready`.

Después abrir la sala:

- el animal aparece en la casilla configurada;
- no atraviesa paredes ni otros objetos;
- el personaje puede rodearlo por las casillas libres;
- la ordenación por Y es correcta al pasar delante y detrás;
- pulsarlo abre la ficha sin mover al personaje;
- ratón y pantalla táctil activan la interacción;
- al acercarse aparece la mano;
- acariciarlo aumenta felicidad y ejecuta la animación;
- cerrar la ficha restaura la pausa correctamente.

## 15. Pruebas de persistencia

1. Entrar en la sala del animal.
2. Anotar sus necesidades y personalidad.
3. Acariciarlo y comprobar que cambia la felicidad.
4. Salir a otra habitación y volver.
5. Verificar que conserva los valores.
6. Abrir y cerrar la ficha varias veces.
7. Si es rescatable, ganar el minijuego y verificar:
   - especie y raza correctas;
   - nombre no vacío;
   - aparición en una casilla libre;
   - una sola instancia;
   - persistencia entre habitaciones;
   - ficha e interacción completas.

Para una prueba automatizada temporal se puede instanciar `game/main.tscn`,
registrar el rescate, restaurarlo en la entrada y usar aserciones sobre:

```gdscript
assert(animal is Ferret)
assert(not animal.pet_name.is_empty())
assert(animal.raza in RAZAS_ESPERADAS)
```

La prueba temporal debe eliminarse después o convertirse en una prueba estable
si el proyecto adopta una carpeta permanente de tests.

## 16. Validación técnica antes de terminar

Ejecutar Godot en modo headless para detectar errores de parseo y recursos:

```powershell
godot --headless --path . --quit-after 4
```

Si `godot` no está en `PATH`, usar la ruta del ejecutable instalado. Después:

```powershell
git diff --check
git status --short
```

Revisar que se incluyan:

- PNG de cada raza;
- `.import` generado por Godot cuando corresponda al flujo del repositorio;
- script y escena base de la especie;
- escenas de raza;
- cambios en enums y traducción del tipo;
- colocaciones en salas;
- cambios de rescate y nombres, si aplican;
- documentación actualizada.

## 17. Lista de verificación final

- [ ] Se ha decidido si es una raza o una especie nueva.
- [ ] La creatividad tiene transparencia, encuadre y estilo coherentes.
- [ ] Carpetas y archivos usan `snake_case`.
- [ ] `tipo` está registrado en `AnimalObject`.
- [ ] Todas las razas están registradas.
- [ ] El tipo tiene nombre visible en español.
- [ ] La clase de especie hereda de `AnimalObject`.
- [ ] La escena base contiene `Visual`, áreas y colisiones esperadas.
- [ ] Cada raza hereda de la escena base y solo aporta datos/textura.
- [ ] Huella visual, base física y navegación coinciden.
- [ ] La escena está colocada mediante `PlacedObjectData` o se crea en runtime.
- [ ] El ID de colocación es único y estable.
- [ ] La ficha muestra nombre, tipo, raza, edad, retrato y necesidades.
- [ ] La descripción de personalidad usa el sustantivo correcto.
- [ ] La acción de acariciar funciona con ratón y toque.
- [ ] El estado persiste al cambiar de habitación.
- [ ] Los nombres y rescates se han generalizado si la especie participa.
- [ ] Se han probado solapamientos, Y-Sort, colisiones y casillas libres.
- [ ] Godot abre el proyecto sin errores de script ni recursos.

## 18. Errores frecuentes

- **La ficha muestra `Ferret` en vez de `Hurón`:** falta el caso en
  `get_tipo_display_name()`.
- **La ficha no abre:** la escena no hereda de `AnimalObject`, no emite
  `selected` o no está siendo administrada por `RoomController`.
- **No aparece retrato:** el sprite no se llama `Visual` o no tiene textura.
- **El animal flota:** el PNG tiene margen transparente inferior o no se usa su
  rectángulo opaco para alinear la base.
- **El dibujo se deforma:** se aplicaron escalas X/Y diferentes; usar la escala
  uniforme de `PettableAnimal`.
- **El personaje atraviesa al animal:** falta el `StaticBody2D`, su forma o
  `provides_own_physics_body = true`.
- **La navegación evita dos casillas en vez de una:** se heredó la huella visual
  como bloqueo; sobrescribir `get_navigation_blocking_cells()`.
- **El animal pierde su estado:** cambió el ID/nombre usado en la clave de
  persistencia o falta un campo en `get_runtime_state()`/`apply_runtime_state()`.
- **El icono de mano no responde:** el área sigue oculta, no es seleccionable o
  no se conectó `input_event`.
- **Una raza nunca aparece rescatada:** su escena no está en el catálogo de
  escenas posibles.
- **Aparecen rescates solapados:** faltan casillas disponibles o la huella de la
  nueva especie no coincide con las reglas del catálogo.
