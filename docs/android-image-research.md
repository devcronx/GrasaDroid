# Investigación: Imagen Android ARM64 con drivers virgl

Fecha: 2026-10-13

## Hallazgo
No existe una imagen Android ARM64 prebuilt pública con drivers virgl/virtio-gpu
lista para descargar. Las opciones son:

### Opción 1: Android-x86 (no sirve)
- android-x86.org tiene ISOs pero son x86_64, no ARM64.
- En iPhone (ARM64) necesitaríamos emular x86_64 -> muy lento sin KVM.

### Opción 2: AOSP ARM64 + kernel virtio-gpu (recomendado)
- Compilar AOSP para `aosp_arm64` con kernel que tenga `CONFIG_DRM_VIRTIO_GPU`.
- El driver virgl en el guest es `virtio-gpu` (kernel) + Mesa con `virpipe` (userspace).
- AOSP ya incluye Mesa; hay que verificar que el build tenga el driver virpipe.

### Opción 3: Usar imagen de UTM/Husk como referencia
- UTM (getutm.app) distribuye VMs pero no Android prebuilt.
- Husk (leviidev/husk) descarga Android pero no se sabe si tiene drivers virgl.

### Opción 4: Bliss OS / Android genérico ARM64
- Algunos proyectos (Vectras-VM) tienen imágenes ARM64 pero sin garantía de virgl.

## Recomendación
Para la Fase B, compilar un kernel Android ARM64 mínimo con:
- CONFIG_DRM_VIRTIO_GPU=y
- CONFIG_DRM_VIRTIO_GPU_KMS=y
Y usar una imagen AOSP `aosp_arm64-userdebug` con Mesa que incluya virpipe.

Alternativa pragmática: empezar con `-device virtio-gpu-pci` (sin virgl, solo 2D)
para validar el boot, luego habilitar virgl cuando el guest tenga los drivers.
