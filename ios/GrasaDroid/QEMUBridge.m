// QEMUBridge.m
// GrasaDroid: Implementación del puente QEMU.
// Carga libqemu-aarch64-softmmu.dylib con dlopen y ejecuta qemu_main en un pthread.

#import "QEMUBridge.h"
#import "QEMUDisplay.h"
#import <dlfcn.h>
#import <pthread.h>

// Tipo de la función main de QEMU
typedef int (*qemu_main_fn)(int argc, char **argv);

@interface QEMUBridge ()
@property (nonatomic, readwrite) QEMUState state;
@property (nonatomic, readwrite) UIView *displayView;
@property (nonatomic) void *qemuHandle;
@property (nonatomic) qemu_main_fn qemuMain;
@property (nonatomic) pthread_t qemuThread;
@property (nonatomic) BOOL threadRunning;
@property (nonatomic) QEMUDisplay *displayBridge;
@end

static QEMUBridge *gShared = nil;

@implementation QEMUBridge

+ (instancetype)shared {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gShared = [[QEMUBridge alloc] init];
    });
    return gShared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = QEMUStateStopped;
    }
    return self;
}

- (void)setState:(QEMUState)state {
    _state = state;
    id<QEMUBridgeDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(qemuDidChangeState:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate qemuDidChangeState:state];
        });
    }
}

- (BOOL)loadQEMULibrary {
    if (self.qemuHandle) return YES;

    NSString *libPath = [[NSBundle mainBundle] pathForResource:@"libqemu-aarch64-softmmu"
                                                        ofType:@"dylib"
                                                   inDirectory:@"Frameworks"];
    if (!libPath) {
        // Intentar en el bundle principal
        libPath = [[NSBundle mainBundle] pathForResource:@"libqemu-aarch64-softmmu"
                                                 ofType:@"dylib"];
    }
    if (!libPath) {
        [self failWithError:@"No se encontró libqemu-aarch64-softmmu.dylib en el bundle"];
        return NO;
    }

    self.qemuHandle = dlopen(libPath.UTF8String, RTLD_NOW | RTLD_GLOBAL);
    if (!self.qemuHandle) {
        [self failWithError:[NSString stringWithFormat:@"dlopen falló: %s", dlerror()]];
        return NO;
    }

    // QEMU expone su main como qemu_main o main
    self.qemuMain = (qemu_main_fn)dlsym(self.qemuHandle, "qemu_main");
    if (!self.qemuMain) {
        self.qemuMain = (qemu_main_fn)dlsym(self.qemuHandle, "main");
    }
    if (!self.qemuMain) {
        [self failWithError:@"No se encontró qemu_main en la librería"];
        return NO;
    }

    return YES;
}

typedef struct {
    QEMUBridge *bridge;
    int argc;
    char **argv;
} QEMUThreadArgs;

static void *qemuThreadEntry(void *arg) {
    QEMUThreadArgs *targs = (QEMUThreadArgs *)arg;
    QEMUBridge *bridge = targs->bridge;

    // QEMU necesita un runloop o señalización para el display.
    // El display bridge se registra antes de llamar a qemu_main.
    int ret = bridge.qemuMain(targs->argc, targs->argv);

    // Liberar argumentos
    for (int i = 0; i < targs->argc; i++) {
        free(targs->argv[i]);
    }
    free(targs->argv);
    free(targs);

    dispatch_async(dispatch_get_main_queue(), ^{
        bridge.threadRunning = NO;
        if (ret == 0) {
            bridge.state = QEMUStateStopped;
        } else {
            [bridge failWithError:[NSString stringWithFormat:@"QEMU terminó con código %d", ret]];
        }
    });

    return NULL;
}

- (void)startWithArguments:(NSArray<NSString *> *)args
                      view:(UIView *)view {
    if (self.state == QEMUStateRunning || self.state == QEMUStateStarting) {
        return;
    }

    self.displayView = view;
    self.state = QEMUStateStarting;

    if (![self loadQEMULibrary]) {
        return;
    }

    // Crear el puente de display antes de arrancar QEMU
    self.displayBridge = [[QEMUDisplay alloc] initWithView:view];
    if (![self.displayBridge setup]) {
        [self failWithError:@"No se pudo inicializar el display"];
        return;
    }

    // Registrar el display bridge con QEMU (vía dlsym de las funciones de registro)
    [self.displayBridge registerWithQEMU:self.qemuHandle];

    // Convertir NSArray a argc/argv
    int argc = (int)args.count + 1;
    char **argv = calloc(argc + 1, sizeof(char *));
    argv[0] = strdup("qemu-system-aarch64");
    for (int i = 0; i < args.count; i++) {
        argv[i + 1] = strdup(args[i].UTF8String);
    }

    QEMUThreadArgs *targs = malloc(sizeof(QEMUThreadArgs));
    targs->bridge = self;
    targs->argc = argc;
    targs->argv = argv;

    self.threadRunning = YES;
    int ret = pthread_create(&_qemuThread, NULL, qemuThreadEntry, targs);
    if (ret != 0) {
        self.threadRunning = NO;
        [self failWithError:@"No se pudo crear el hilo de QEMU"];
        return;
    }
    pthread_detach(self.qemuThread);

    self.state = QEMUStateRunning;
}

- (void)stop {
    // TODO: Enviar señal de apagado a QEMU vía qmp o similar
    self.state = QEMUStateStopped;
}

- (void)setPaused:(BOOL)paused {
    // TODO: Implementar pausa vía monitor QMP
}

- (void)failWithError:(NSString *)error {
    self.state = QEMUStateError;
    id<QEMUBridgeDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(qemuDidFailWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate qemuDidFailWithError:error];
        });
    } else {
        NSLog(@"[GrasaDroid] QEMU error (sin delegate): %@", error);
    }
}

@end
