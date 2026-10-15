// iOS host layer (runtime/platform.h).
// Basado en macos.c, adaptado para iOS.
// iOS no tiene mach/mach_vm.h - usar mmap en su lugar.
#include <dlfcn.h>
#include <execinfo.h>
#include <mach-o/dyld.h>
#include <mach/mach_time.h>
#include <mach/thread_policy.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/ucontext.h>
#include <unistd.h>

#include "../platform.h"

static mach_timebase_info_data_t tb;

void ios_touch_init(void);

void plat_init(void) {
#ifdef PLATFORM_IOS
    ios_touch_init();
#endif
}

bool plat_reserve_guest(uint64_t lo, uint64_t hi) {
    // iOS: usar mmap con MAP_FIXED en lugar de mach_vm_allocate
    void *p = mmap((void *)(uintptr_t)lo, hi - lo,
                   PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0);
    return p != MAP_FAILED;
}

bool plat_reset_guest(uint64_t lo, uint64_t hi) {
    void *p = mmap((void *)(uintptr_t)lo, hi - lo,
                   PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANON | MAP_FIXED, -1, 0);
    return p != MAP_FAILED;
}

void plat_commit(uint64_t addr, uint64_t size) { (void)addr; (void)size; }

int plat_protect(uint64_t addr, uint64_t size, int prot) {
    int p = prot == PLAT_PROT_NONE ? PROT_NONE : prot == PLAT_PROT_READ ? PROT_READ : PROT_READ | PROT_WRITE;
    return mprotect((void *)(uintptr_t)addr, size, p);
}

uint64_t plat_now_ns(void) {
    if (!tb.denom) mach_timebase_info(&tb);
    return mach_absolute_time() * tb.numer / tb.denom;
}

void plat_sleep_until_ns(uint64_t t) {
    uint64_t now = plat_now_ns();
    if (t <= now) return;
    uint64_t diff_ns = t - now;
    struct timespec ts = {
        .tv_sec = diff_ns / 1000000000,
        .tv_nsec = diff_ns % 1000000000
    };
    nanosleep(&ts, NULL);
}

void plat_thread_realtime(uint64_t period_ns) {
    // iOS no soporta thread_policy_set como macOS - usar QoS en su lugar
    // Por ahora no-op; el hilo ya corre con prioridad adecuada
    (void)period_ns;
}

bool plat_exe_path(char *buf, size_t size) {
    uint32_t len = (uint32_t)size;
    return _NSGetExecutablePath(buf, &len) == 0;
}

void plat_exec(char *const argv[]) {
    // iOS no permite exec - no-op
    (void)argv;
}

const char *plat_symbol(uint64_t pc, uint64_t *offset) {
    Dl_info di = {0};
    if (!dladdr((void *)(uintptr_t)pc, &di) || !di.dli_sname) return NULL;
    if (offset) *offset = pc - (uint64_t)(uintptr_t)di.dli_saddr;
    return di.dli_sname;
}

void plat_fatal_notice(void) {}

void plat_print_backtrace(void) {
    void *bt[64];
    int n = backtrace(bt, 64);
    char **syms = backtrace_symbols(bt, n);
    for (int i = 0; i < n; i++) fprintf(stderr, "  %s\n", syms[i]);
}

static void crash_handler(int sig, siginfo_t *si, void *ctx) {
    ucontext_t *uc = ctx;
    static volatile int depth;
    if (sig == SIGABRT && depth++ > 0) { signal(SIGABRT, SIG_DFL); abort(); }
    uint64_t fa = (uint64_t)si->si_addr;
    // iOS: obtener PC de forma portable
    uint64_t pc = 0, lr = 0;
#if defined(__aarch64__)
    pc = uc->uc_mcontext->__ss.__pc;
    lr = uc->uc_mcontext->__ss.__lr;
#endif
    if (rt_fault_watch(fa, pc)) return;
    char what[32];
    snprintf(what, sizeof what, "signal %d", sig);
    rt_fault_report(what, fa, pc, lr);
}

void plat_crash_handler_install(void) {
    stack_t ss = {.ss_sp = malloc(1 << 20), .ss_size = 1 << 20};
    sigaltstack(&ss, NULL);
    struct sigaction sa = {0};
    sa.sa_sigaction = crash_handler;
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGBUS, &sa, NULL);
    sigaction(SIGILL, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
}

// ---- child processes: no soportado en iOS
// (PlatProc ya está definido como intptr_t en platform.h)

PlatProc plat_spawn(const char *const argv[], const char *log_path, bool append_log) {
    (void)argv; (void)log_path; (void)append_log;
    return 0;
}

int plat_proc_wait(PlatProc p, bool block) {
    (void)p; (void)block;
    return 255;
}

bool plat_remove_tree(const char *dir) {
    // iOS no tiene system() - no-op por ahora
    // TODO: implementación recursiva manual
    (void)dir;
    return false;
}
