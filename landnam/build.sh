#!/usr/bin/env bash
# Compila Godot con este módulo (rama mejoras-landnam) y los parches de landnam/patches/godot.
#
#   landnam/build.sh                         # editor
#   landnam/build.sh template_release template_debug   # plantillas de exportación
#
# Variables: GODOT_DIR (por defecto ../godot junto al módulo), GODOT_TAG (4.6-stable), JOBS.
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
	nice -n 10 scons platform=linuxbsd target="$target" debug_symbols=no -j"$JOBS"
done
ls -la bin/
