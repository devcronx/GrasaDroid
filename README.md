# GrasaDroid — emulador de Android para iOS

Un emulador de Android para iPhone, instalado por sideload como IPA.
Diseñado **JIT-first**: donde Husk improvisa el JIT, GrasaDroid lo pide
desde el diseño.

## Estado

**M1 — shell + pipeline (en curso).** La app abre y el pipeline
nube → IPA → sideload queda probado. El motor QEMU (M2) es el siguiente hito.

> Nota honesta: esto es un proyecto de sistemas de meses, no de días.
> Cada hito se prueba antes de declararse listo.

## Arquitectura (resumen)

```
iPhone (iOS stock, sideload)
 └─ GrasaDroid.app (UIKit)
     ├─ Núcleo QEMU — emulación de sistema ARM64 (TCG + JIT)
     ├─ Invitado Android ARM64 (imagen mínima)
     ├─ Display: framebuffer del invitado -> UIView (Metal)
     └─ Input: táctil -> eventos del invitado
```

- **Sin jailbreak, sin hipervisor** (iOS no lo permite a apps de sideload).
- **JIT vía StikDebug + pairing file**: el núcleo usa el motor JIT de TCG;
  StikDebug lo habilita en runtime. Sin StikDebug, TCG cae a intérprete.
- Ver `docs/ARCHITECTURE.md` para el diseño completo y `docs/ROADMAP.md`
  para los hitos.

## Compilar

Cada push a `main` compila en GitHub Actions (`macos-14`) y publica el IPA
sin firmar como artefacto `GrasaDroid-IPA`. Instalar con Sideloadly/AltStore.

## Licencia

Por definir. Nota: si el núcleo QEMU deriva de UTM (GPL), este proyecto
hereda copyleft — decisión pendiente antes de M2.
