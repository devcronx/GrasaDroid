# Puente de Display: virgl → ANGLE → Metal

## Arquitectura

```
Guest (Android ARM64)
  → virtio-gpu (kernel driver)
  → virglrenderer (host, en QEMU)
  → EGL/ANGLE (traduce GL → Metal)
  → QEMUDisplay (nuestro código)
  → CAMetalLayer (pantalla del iPhone)
```

## Cómo funciona

1. **QEMU arranca** con `-device virtio-gpu-gl-pci -display egl`
2. **virglrenderer** procesa los comandos 3D del guest usando el GPU del host (vía ANGLE→Metal)
3. Cuando hay un frame listo, QEMU llama a `dpy_gl_scanout_texture` en nuestro `DisplayChangeListener`
4. Recibimos el `backing_id` (un texture GL) con las dimensiones
5. Leemos los píxeles y los presentamos en el `CAMetalLayer`

## Estado actual

- ✅ `DisplayChangeListener` definido con ops GL
- ✅ `register_displaychangelistener` resuelto via dlsym
- ✅ `dpy_gl_scanout_texture` implementado (recibe texture_id)
- ✅ `CAMetalLayer` configurado
- ⏳ Blit real de píxeles (requiere guest corriendo para probar el contexto GL)
- ⏳ Optimización con IOSurface compartido (evitar copia CPU)

## Próximos pasos

1. Probar con un guest real para validar el contexto EGL compartido
2. Implementar `glReadPixels` → `MTLTexture` en `presentFrame`
3. Optimizar con `ANGLE_metal` o `IOSurface` para zero-copy
4. Manejar `dpy_gl_scanout_dmabuf` para buffers DMA (más eficiente)
