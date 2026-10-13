//
//  JITEnabler.m
//  GrasaDroid
//
//  Self-debugging para habilitar JIT sin StikDebug externo.
//

#import "JITEnabler.h"
#import <sys/wait.h>
#import <unistd.h>
#import <signal.h>
#import <sys/mman.h>
#import <pthread.h>
#import <errno.h>
#import <string.h>

// ptrace no está en el SDK de iOS, declarar manualmente
#define PT_TRACE_ME 0
#define PT_ATTACH 10
#define PT_CONTINUE 7
#define PT_DETACH 11
int ptrace(int request, pid_t pid, caddr_t addr, int data);

// Sin MAP_JIT en algunos SDKs, definirlo
#ifndef MAP_JIT
#define MAP_JIT 0x800
#endif

static pid_t g_helperPid = -1;
static pid_t g_targetPid = -1;
static volatile int g_debuggerRunning = 0;

/// Bucle del debugger: espera eventos del proceso trazado y lo continúa.
/// Corre en el proceso helper (hijo del fork).
static void debugger_loop(pid_t target) {
    int status = 0;

    // Esperar el SIGSTOP inicial del PT_ATTACH
    while (g_debuggerRunning) {
        pid_t w = waitpid(target, &status, 0);
        if (w == -1) {
            // El objetivo murió o hubo error
            break;
        }
        if (WIFEXITED(status) || WIFSIGNALED(status)) {
            break;
        }
        // Continuar la ejecución (pasar la señal si no es SIGTRAP)
        int sig = 0;
        if (WIFSTOPPED(status)) {
            int stopsig = WSTOPSIG(status);
            // No reenviar SIGTRAP ni SIGSTOP, continuar limpio
            if (stopsig != SIGTRAP && stopsig != SIGSTOP) {
                sig = stopsig;
            }
        }
        if (ptrace(PT_CONTINUE, target, (caddr_t)1, sig) == -1) {
            break;
        }
    }
}

@implementation JITEnabler

+ (BOOL)enableJIT {
    // Si ya está habilitado, no hacer nada
    if (g_helperPid != -1) {
        return [self isJITAvailable];
    }

    // Si JIT ya funciona (debugger externo como StikDebug), no hacer nada
    if ([self isJITAvailable]) {
        NSLog(@"[GrasaDroid] JIT ya disponible (debugger externo)");
        return YES;
    }

    g_targetPid = getpid();
    g_debuggerRunning = 1;

    pid_t helper = fork();
    if (helper == -1) {
        NSLog(@"[GrasaDroid] fork() falló: %s", strerror(errno));
        g_debuggerRunning = 0;
        return NO;
    }

    if (helper == 0) {
        // === Proceso helper (hijo) ===
        // Cerrar descriptores innecesarios para no interferir
        // Adjuntarse al padre como debugger
        if (ptrace(PT_ATTACH, g_targetPid, NULL, 0) == -1) {
            NSLog(@"[GrasaDroid] PT_ATTACH falló: %s", strerror(errno));
            _exit(1);
        }

        NSLog(@"[GrasaDroid] Debugger helper adjuntado al pid %d", g_targetPid);
        debugger_loop(g_targetPid);
        _exit(0);
    }

    // === Proceso principal (padre) ===
    g_helperPid = helper;

    // Dar tiempo al helper para que haga PT_ATTACH
    // El SIGSTOP nos pausará; el helper nos continuará
    int tries = 0;
    while (tries < 50 && ![self isJITAvailable]) {
        usleep(100000); // 100ms
        tries++;
    }

    BOOL ok = [self isJITAvailable];
    NSLog(@"[GrasaDroid] Self-debugging %@ (JIT %@)",
          ok ? @"exitoso" : @"falló",
          ok ? @"disponible" : @"no disponible");
    return ok;
}

+ (BOOL)isJITAvailable {
    const size_t pageSize = 16384;
    void *ptr = mmap(NULL, pageSize,
                     PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANON | MAP_JIT,
                     -1, 0);
    if (ptr == MAP_FAILED) {
        return NO;
    }
    // Probar que podemos hacerlo ejecutable (lo que QEMU necesita)
    if (mprotect(ptr, pageSize, PROT_READ | PROT_EXEC) != 0) {
        munmap(ptr, pageSize);
        return NO;
    }
    munmap(ptr, pageSize);
    return YES;
}

+ (void)disableJIT {
    g_debuggerRunning = 0;
    if (g_helperPid != -1) {
        // Detach del proceso trazado
        ptrace(PT_DETACH, g_targetPid, NULL, 0);
        kill(g_helperPid, SIGTERM);
        g_helperPid = -1;
    }
}

@end
