# Roadmap — GrasaDroid

Regla: ningún hito se declara listo sin prueba en dispositivo.

## M1 — Shell + pipeline (AHORA)
- [x] Estructura del repo y docs
- [x] App iOS mínima (abre, pantalla negra + etiqueta)
- [x] Workflow GitHub Actions (macos-14): compila y publica IPA sin firmar
- [ ] Primer IPA instalado en el iPhone por sideload ← prueba de fuego

## M2 — Núcleo QEMU
- [ ] QEMU `aarch64-softmmu` compilado para iOS en CI
- [ ] TCG con JIT integrado como librería estática en la app
- [ ] La app arranca QEMU y muestra su salida (aunque sea una pantalla vacía)
- [ ] Prueba: con StikDebug+JIT corre; sin JIT cae a intérprete sin crashear

## M3 — Android arranca
- [ ] Imagen Android ARM64 mínima + kernel con BinderFS
- [ ] Arranque directo kernel+initramfs sobre máquina `virt`
- [ ] Prueba: Android llega a shell (adb) dentro de la app

## M4 — Usable
- [ ] Display del invitado en la pantalla del iPhone
- [ ] Táctil funcional
- [ ] `adb install` de una APK de prueba y la app abre

## M5 — Grasa de verdad
- [ ] Un solo IPA, instalación guiada
- [ ] Ajustes (RAM, resolución), diagnóstico en pantalla
- [ ] Comparativa contra Husk: misma APK, medir fps/tiempo de arranque
