# Arquitectura — GrasaDroid

## Objetivo

Correr apps Android (APKs) en iPhone con iOS stock, instalado por sideload,
a velocidad usable. Competir con Husk en: instalación simple (un solo IPA),
rendimiento (JIT-first) y compatibilidad.

## Restricciones de la plataforma (iOS stock)

1. **Sin Hypervisor.framework** para apps de terceros → no hay virtualización;
   solo emulación (QEMU TCG).
2. **Sin JIT por defecto** en apps de sideload → se habilita vía StikDebug +
   pairing file (requiere una PC una sola vez para generar el pairing).
3. **Sin acceso USB directo**, memoria limitada, sin dynamic-codesigning libre.

## Componentes

### 1. App shell (iOS, UIKit) — M1 ✅ en curso
`ios/GrasaDroid/`: AppDelegate, SceneDelegate, ViewController placeholder.
Prueba el pipeline de compilación. Aquí vivirá la vista del display y el
manejo de input.

### 2. Núcleo QEMU — M2
- QEMU en modo sistema, target `aarch64-softmmu`, compilado para iOS (arm64).
- Acelerador TCG con JIT. Misma arquitectura (ARM64→ARM64): TCG traduce
  igual, con sobrecosto, pero JIT lo deja en rango usable en un A19 Pro.
- Referencia: el port de QEMU a iOS de UTM (open source) es la base probada;
  evaluar fork vs. reimplementación mínima del build.
- Sin JIT (sin StikDebug): TCG en modo intérprete — lento, solo para pruebas.

### 3. Invitado Android — M3
- Android ARM64 mínimo (AOSP/Redroid) con kernel ARM64 directo (sin GRUB/ISO).
- Arranque directo kernel+initramfs sobre `virt` de QEMU (evita BIOS/UEFI).
- BinderFS necesario para el userspace Android.

### 4. Display + input — M4
- Framebuffer del invitado (virtio-gpu o framebuffer simple) → UIView/Metal.
- Táctil iOS → eventos multitouch del invitado (virtio-input).
- Instalación de APKs: `adb install` contra el invitado vía red local QEMU.

### 5. Pulido — M5
- Un solo IPA (imagen Android embebida o descarga guiada dentro de la app).
- Ajustes: RAM, núcleos, resolución. Diagnóstico en pantalla.

## Dónde le ganamos a Husk

1. **JIT-first**: el núcleo se diseña para JIT desde el día uno; Husk lo
   añade como parche sobre un contenedor sin JIT.
2. **Instalación**: un IPA, sin descargas separadas de 4 GB por fuera.
3. **Android afinado**: imagen mínima pensada para táctil, no un Linux
   genérico con Android encima.
