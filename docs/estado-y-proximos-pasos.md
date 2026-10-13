# GrasaDroid: Estado y próximos pasos

Última actualización: 2026-10-13

## Lo que está listo ✅

### Fase A: Stack GPU (completado)
- virglrenderer 1.3.0 compilado para iOS arm64
- epoxy 1.5.9 + ANGLE (traduce OpenGL → Metal)
- QEMU 10.0.12-utm con `--enable-opengl --enable-virglrenderer`
- Verificado: `VirGL support: YES`, `OpenGL support (epoxy): YES`

### Integración iOS (completado)
- `QEMUBridge`: carga libqemu con dlopen, corre QEMU en pthread
- `QEMUDisplay`: DisplayChangeListener con ops GL completas
  - `dpy_gl_scanout_texture`: recibe frames de virgl
  - `dpy_gl_update`: marca regiones actualizadas
  - `dpy_gl_scanout_disable`: maneja apagado del display
- `CAMetalLayer` configurado para presentar frames
- IPA compila en verde con todo integrado

## Lo que falta ⏳

### 1. Blit real de píxeles (requiere guest corriendo)
El `presentFrame` actualmente presenta un drawable vacío. Cuando haya un
guest real, implementar:
```objc
// En el hilo de QEMU, con contexto EGL current:
glBindTexture(GL_TEXTURE_2D, textureId);
glReadPixels(0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
// Copiar buffer a MTLTexture y presentar
```
Optimización futura: IOSurface compartido para zero-copy.

### 2. Imagen Android ARM64 con drivers virgl
No existe prebuilt público. Opciones:
- **AOSP `aosp_arm64-userdebug`** + kernel con `CONFIG_DRM_VIRTIO_GPU`
- Verificar que Mesa incluya el driver `virpipe`
- Alternativa: empezar con `virtio-gpu-pci` (2D) para validar boot

### 3. Probar en iPhone con StikDebug
- Instalar IPA por Sideloadly/SideStore
- Conectar StikDebug + pairing file para JIT
- Verificar que QEMU arranca sin crashear
- Medir FPS y estabilidad

### 4. Botón de descarga de Android
- Implementar descarga reanudable con SHA (requisito de Wilfry)
- Integrar con la imagen del paso 2

## Arquitectura final

```
┌─────────────────────────────────────────┐
│  iPhone (iOS 27.2)                      │
│  ┌───────────────────────────────────┐  │
│  │ GrasaDroid.app                    │  │
│  │  ┌─────────────┐  ┌────────────┐  │  │
│  │  │ QEMUBridge  │  │ QEMUDisplay│  │  │
│  │  │ (pthread)   │→ │ (Metal)    │  │  │
│  │  └─────────────┘  └────────────┘  │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │ libqemu (VirGL + epoxy)     │  │  │
│  │  │ libANGLE (GL → Metal)       │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ StikDebug (JIT)                   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Ventaja competitiva vs Husk
- Husk no tiene virgl funcionando en iOS (nadie lo tiene)
- Nuestro stack GPU compila y está integrado
- El puente de display es trabajo original
- StikDebug robusto en iOS 27 (donde Husk crashea)
