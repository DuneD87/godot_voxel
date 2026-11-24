#!/usr/bin/env bash
# Compila Godot con este módulo (rama mejoras-landnam) y los parches de landnam/patches/godot.
#
#   landnam/build.sh                         # editor
#   landnam/build.sh template_release template_debug   # plantillas de exportación
#
# Variables: GODOT_DIR (por defecto ../godot junto al módulo), GODOT_TAG (4.6-stable), JOBS, y
# EXTRA_SCONS para opciones de scons adicionales.
#
# Mismas opciones que los ejecutables del CI del módulo (.github/workflows/linux.yml, filas con
# artefacto): production=yes, que en Linux con GCC activa LTO completo y libstdc++ estática. Sin ella
# el motor sale entre un 10 y un 20 % más lento de CPU. El enlazado con LTO pide mucha memoria y
# tarda varios minutos.
# Si GODOT_DIR no existe, clona Godot en GODOT_TAG. Los parches ya aplicados se saltan.
set -euo pipefail

MODULE_DIR=$(cd "$(dirname "$0")/.." && pwd)
GODOT_DIR=${GODOT_DIR:-"$MODULE_DIR/../godot"}
GODOT_TAG=${GODOT_TAG:-4.6-stable}
JOBS=${JOBS:-$(( $(nproc) > 2 ? $(nproc) - 2 : 1 ))}
TARGETS=("$@")
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(editor)

if [ ! -d "$GODOT_DIR/.git" ]; then
	git clone --depth 1 --branch "$GODOT_TAG" https://github.com/godotengine/godot.git "$GODOT_DIR"
fi
cd "$GODOT_DIR"

for patch in "$MODULE_DIR"/landnam/patches/godot/*.patch; do
	[ -e "$patch" ] || continue
	if git apply --reverse --check "$patch" 2>/dev/null; then
		echo "ya aplicado: $(basename "$patch")"
	else
		git apply "$patch"
		echo "aplicado: $(basename "$patch")"
	fi
done

ln -sfn "$MODULE_DIR" modules/voxel

for target in "${TARGETS[@]}"; do
	# production=yes (LTO): sin ella el binario rendía ~20 fps menos que el oficial (medido 2026-11-18, RTX 4080).
	# shellcheck disable=SC2086
	nice -n 10 scons platform=linuxbsd target="$target" production=yes tests=no dev_build=no \
		debug_symbols=no -j"$JOBS" ${EXTRA_SCONS:-}
done
ls -la bin/
