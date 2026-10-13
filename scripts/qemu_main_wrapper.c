/*
 * qemu_main_wrapper.c - Expone qemu_main para GrasaDroid iOS
 *
 * QEMU construido con --enable-shared-lib no exporta main().
 * Este wrapper proporciona el punto de entrada que GrasaDroid busca via dlsym.
 */

#include <stdio.h>

/* Declaración del main real de QEMU (en system/main.c) */
extern int main(int argc, char **argv);

/*
 * Punto de entrada para GrasaDroid.
 * Llamado via dlsym("qemu_main") desde QEMUBridge.
 */
__attribute__((visibility("default")))
int qemu_main(int argc, char **argv) {
    return main(argc, argv);
}
