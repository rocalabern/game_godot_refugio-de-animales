# Sistema OOP y configuración de animales

Este documento describe la arquitectura orientada a objetos, los recursos de
configuración y el flujo de ejecución de los animales del refugio.

## Objetivos del diseño

El sistema separa cuatro conceptos que cambian a ritmos distintos:

1. **Contrato de sala:** colocación, navegación e interacción.
2. **Estado de animal:** identidad individual, necesidades y personalidad.
3. **Comportamiento de especie:** gato, perro o ave.
4. **Configuración de subraza:** imagen, tamaño, edad y catálogo de nombres.

Una subraza tiene un objeto de datos y una escena instanciable, pero no necesita
una clase GDScript propia mientras no tenga comportamiento exclusivo.

## Jerarquía de clases

```text
PlaceableObject
└── AnimalObject
    └── PettableAnimal
        ├── Cat
        ├── Dog
        └── Bird
```

### `PlaceableObject`

Archivo: `entities/shared/placeable_object.gd`.

Es el contrato mínimo de cualquier objeto de una habitación. Define:

- `base_cell`: casilla inferior izquierda usada para colocar el objeto.
- `footprint`: dimensiones visuales calculadas o declaradas.
- bloqueo de navegación;
- Y-Sort;
- interacción genérica;
- desplazamiento del punto de anclaje respecto a la cuadrícula.

Las habitaciones trabajan con este contrato y no necesitan conocer clases
concretas.

### `AnimalObject`

Archivo: `entities/animals/animal_object.gd`.

Añade al objeto colocable:

- referencia a `AnimalBreedDefinition`;
- identidad resuelta (`tipo`, `raza`, `edad`, `nombre` y `pet_name`);
- salud, hambre, higiene, felicidad y energía;
- rasgos de personalidad;
- acciones comunes como alimentar, jugar, limpiar y cuidar;
- serialización y restauración del estado de partida.

`tipo`, `raza`, `edad` y `nombre` no se configuran ya por separado en cada
escena. `apply_breed_definition()` los obtiene de la definición de subraza.

Cuando un ejemplar no tiene `pet_name`, `initialize_runtime_state()` solicita
uno a su definición. El nombre se guarda también en `get_runtime_state()` para
que permanezca al cambiar de habitación.

### `PettableAnimal`

Archivos:

- `entities/animals/pettable_animal.gd`;
- `entities/animals/pettable_animal.tscn`.

Centraliza el comportamiento compartido por los animales actuales:

- nodo `Visual`;
- cuerpo físico y área de interacción;
- escala uniforme manteniendo el aspect ratio;
- cálculo automático de filas visuales;
- base física de una o varias columnas;
- casillas visuales, bloqueadas y de interacción;
- detección de cercanía del jugador;
- icono de la mano;
- interacción con ratón y pantalla táctil;
- animación al acariciar;
- compatibilidad con el modo de edición.

### `Cat`, `Dog` y `Bird`

Archivos bajo `entities/animals/cats`, `dogs` y `birds`.

Son las tres clases concretas de especie. Actualmente son deliberadamente
pequeñas porque todo el comportamiento compartido vive en `PettableAnimal`.

Una clase de especie puede sobrescribir un método si todos sus animales deben
comportarse de forma diferente. Una clase de subraza solo debe crearse cuando
esa subraza tenga lógica exclusiva que no pueda expresarse mediante datos.

## Objetos de configuración

```text
AnimalBreedDefinition
├── identidad de subraza
├── AnimalNamePool
├── textura
├── ancho visual
├── ancho físico
└── edad predeterminada

AnimalNamePool
└── lista reutilizable de nombres
```

### `AnimalBreedDefinition`

Script: `entities/animals/config/animal_breed_definition.gd`.

Existe un recurso `.tres` por subraza bajo
`entities/animals/config/breeds/<tipo>/`.

Campos:

| Campo | Responsabilidad |
|---|---|
| `animal_type` | `Cat`, `Dog` o `Bird` |
| `breed_id` | Identificador técnico estable en `snake_case` |
| `display_name` | Nombre mostrado en la ficha |
| `default_age` | Edad inicial del ejemplar |
| `name_pool` | Catálogo de nombres permitido |
| `visual_columns` | Ancho con el que se escala la parte opaca del PNG |
| `base_columns` | Casillas inferiores de colisión y navegación |
| `visual_texture` | Creatividad de la subraza |

La definición implementa:

- `pick_random_name()`, que delega en el catálogo;
- `get_validation_errors()`, que comprueba identidad, nombres, textura y
  coherencia geométrica.

`base_columns` no puede ser mayor que `visual_columns`.

### `AnimalNamePool`

Script: `entities/animals/config/animal_name_pool.gd`.

Los catálogos viven en `entities/animals/config/name_pools/`. Cada uno contiene
un `pool_id` estable y un `PackedStringArray` de nombres. Varias subrazas pueden
referenciar el mismo recurso sin duplicar la lista.

`pick_random_name()` utiliza el `RandomNumberGenerator` de la partida. La
selección es con reemplazo: distintos animales pueden recibir el mismo nombre.

## Catálogo actual de subrazas

| Tipo | `breed_id` | Nombre visible | Pool | Visual | Base |
|---|---|---|---|---:|---:|
| Cat | `siamese` | Siamés | `cats` | 1 | 1 |
| Cat | `bengal` | Bengalí | `cats` | 1 | 1 |
| Cat | `british_shorthair` | British Shorthair | `cats` | 1 | 1 |
| Cat | `persian` | Persa | `cats` | 1 | 1 |
| Dog | `beagle` | Beagle | `dogs_small` | 1 | 1 |
| Dog | `german_sheperd` | Pastor alemán | `dogs_large` | 2 | 2 |
| Dog | `huskie` | Husky | `dogs_large` | 2 | 2 |
| Dog | `poodle` | Caniche | `dogs_small` | 1 | 1 |
| Bird | `budgie_green` | Periquito verde | `budgies` | 1 | 1 |
| Bird | `budgie_white` | Periquito blanco | `budgies` | 1 | 1 |
| Bird | `great_horned_owl` | Gran búho cornudo | `owls` | 1 | 1 |
| Bird | `screech_owl` | Búho chillón | `owls` | 1 | 1 |

Los nombres técnicos existentes `german_sheperd` y `huskie` se conservan para
no romper rutas de recursos, aunque su ortografía inglesa convencional sea
`german_shepherd` y `husky`.

## Catálogos de nombres

### Gatos: `cats.tres`

Usado por las cuatro subrazas de gato:

```text
Misha, Simba, Pelusa, Cleo, Leo, Mochi, Aria, Botitas, Misi, Misu,
Sunny, Noche, Ebano, Cosmo
```

### Beagle y caniche: `dogs_small.tres`

```text
Toby, Bella, Luna, Maya, Canela, Milo, Kiwi, Coco, Otto
```

### Pastor alemán y husky: `dogs_large.tres`

```text
Toby, Kira, Luna, Maya, Max, Rocky, Lola, Zeus, Bruno, Nala, Tyson,
Layca, Loki, Thor, Sky, Sombra
```

### Periquitos: `budgies.tres`

```text
Pepe, Pico, Limon, Azul, Jade, Bartolo, Atenea, Nimbus, Strix
```

### Búhos: `owls.tres`

```text
Arquimedes, Merlin, Orion, Sabio, Hecato, Lumos, Onice, Limbus, Auryn
```

Los nombres se almacenan sin espacios iniciales o finales. Se mantiene la
grafía proporcionada por diseño de contenido.

## Relación entre definición y escena

Cada subraza mantiene una escena concreta. Por ejemplo:

```text
huskie.tscn
└── hereda de dog.tscn
    └── hereda de pettable_animal.tscn
```

La escena solo referencia su objeto de configuración:

```gdscript
[ext_resource type="Resource"
path="res://entities/animals/config/breeds/dogs/huskie.tres"
id="2_breed"]

[node name="DogHuskie" instance=ExtResource("1_dog")]
breed_definition = ExtResource("2_breed")
```

La escena es un `PackedScene`: una plantilla instanciable. El `.tres` es el
objeto de datos de la subraza. El ejemplar vivo aparece cuando una habitación o
el `GameController` llama a `instantiate()`.

## Geometría y aspect ratio

`visual_columns` determina exclusivamente el ancho de la zona opaca:

```gdscript
target_width = visual_columns * cell_size.x
scale_factor = target_width / opaque_width
visual.scale = Vector2.ONE * scale_factor
```

La misma escala se aplica a ambos ejes, por lo que el PNG no se deforma. La
altura resultante determina automáticamente `visual_rows`.

`base_columns` controla una sola fila física:

```text
Animal normal:       Husky/pastor alemán:
┌────┐               ┌────┬────┐
│ X  │               │ X  │ X  │
└────┘               └────┴────┘
```

`base_cell` siempre identifica la casilla inferior izquierda. El nodo se centra
sobre la base completa mediante `get_cell_anchor_offset()`.

## Flujo de creación en una habitación

```text
RoomData
  ↓ PlacedObjectData(scene, base_cell)
RoomController.instantiate_placements()
  ↓ instantiate()
PettableAnimal._ready()
  ↓ apply_breed_definition()
Identidad + textura + geometría
  ↓ initialize_runtime_state()
Nombre + necesidades + personalidad
```

`RoomController` consume el resultado como `AnimalObject`, conecta la señal
genérica de interacción y reconstruye navegación desde las casillas bloqueadas.

## Flujo de rescate

`GameController` mantiene las doce escenas en `RESCUABLE_ANIMAL_SCENES`, pero ya
no contiene nombres ni reglas específicas de raza.

```text
Victoria en el minijuego
  ↓
Elegir una escena aleatoria
  ↓
Leer AnimalBreedDefinition
  ↓
Validar configuración
  ↓
breed_definition.pick_random_name(random)
  ↓
Reservar base_columns casillas
  ↓
Guardar scene + pet_name + base_cell + base_columns
  ↓
Instanciar en shelter_entrada
```

La escena elegida determina por sí misma qué nombres, textura y dimensiones
utiliza. Para hacer rescatable una nueva subraza hay que agregar su escena al
catálogo de escenas, no modificar la lógica de nombres.

## Persistencia

`GameController.animal_states` conserva el estado por sala e ID de nodo. El
diccionario de cada animal incluye:

- `pet_name`;
- necesidades;
- felicidad;
- rasgos de personalidad.

La identidad de subraza no se duplica en el estado porque procede de la escena y
su `AnimalBreedDefinition`. Los rescates guardan la escena concreta, que vuelve
a proporcionar esa definición al restaurarse.

## Añadir una subraza

1. Añadir el PNG bajo `assets/animals/<tipo>/<breed_id>/`.
2. Elegir un catálogo existente o crear un `AnimalNamePool`.
3. Crear `entities/animals/config/breeds/<tipo>/<breed_id>.tres`.
4. Configurar tipo, ID, nombre visible, edad, pool, textura y columnas.
5. Crear una escena que herede de la escena de especie.
6. Asignar únicamente `breed_definition` en la escena.
7. Añadir la escena a una habitación o a `RESCUABLE_ANIMAL_SCENES`.
8. Ejecutar validaciones de carga, nombre, geometría, ficha y persistencia.

## Cuándo crear una clase de subraza

No crear una clase solo para cambiar:

- nombres;
- textura;
- tamaño;
- edad;
- estadísticas configurables;
- futuros `SpriteFrames` configurables.

Sí puede tener sentido crear `Husky extends Dog` si incorpora comportamiento
programado exclusivo, por ejemplo una habilidad, una máquina de estados o una
interacción que no comparte con otros perros. Esa clase seguiría consumiendo su
`AnimalBreedDefinition` para los datos.

## Validación y errores frecuentes

`AnimalBreedDefinition.get_validation_errors()` detecta:

- `breed_id` vacío;
- nombre visible vacío;
- catálogo ausente o vacío;
- nombre vacío dentro de un catálogo;
- base más ancha que el visual;
- textura ausente.

Errores habituales:

- **Nombre de otro grupo:** la definición referencia el pool incorrecto.
- **Imagen o tamaño incorrectos:** la escena todavía contiene valores antiguos
  en vez de delegarlos en `breed_definition`.
- **Nombre que cambia al volver:** `pet_name` no se incluyó en el estado.
- **Rescate sin nombre:** catálogo vacío o definición ausente.
- **Raza no rescatable:** su escena no está en `RESCUABLE_ANIMAL_SCENES`.
- **Solapamiento:** `base_columns` no representa la base física real.
