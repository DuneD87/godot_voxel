# Rama mejoras-landnam

Voxel Tools 1.6 con cambios para el juego landnam (Godot 4.6-stable, Linux). Cada cambio es un commit
propio sobre `v1.6` con el porqué y lo medido en el mensaje; `git log v1.6..mejoras-landnam`.

Resumen:
- El instancer ya no descarga desde la GPU las transformadas de un bloque al darle colisión ni al
  cambiarle la malla por LOD (paradas de 6-13 ms por bloque al moverse).
- Presupuestos por fotograma que de verdad cortan: colisión del instancer tras cada bloque, colisión del
  terreno en trozos (`deferred_collision_min_lod`, `collision_build_budget_usec`) y retirada de bloques del
  instancer (`block_exit_budget_microseconds`). Por defecto todo se comporta como el original.
- `VoxelInstancer.get_instance_transforms_in_sphere()`, `get_instances_revision()`, `get_statistics()`;
  `VoxelLodTerrain.shadow_casting_max_lod` y contadores acumulados en `get_statistics()`.

`patches/godot/` lleva lo que hace falta cambiar en el propio Godot (hoy, que Jolt construya también las
formas desactivadas al añadirlas). `build.sh` clona Godot si no está, aplica los parches, enlaza este
módulo como `modules/voxel` y compila; sin argumentos, el editor. Las plantillas de exportación necesitan
los mismos cambios: `landnam/build.sh template_release template_debug`.

Para traer cambios de Zylann: `git fetch upstream` y rebasar la rama sobre la versión nueva; los parches
de Godot hay que comprobarlos contra la versión de Godot que se use.
