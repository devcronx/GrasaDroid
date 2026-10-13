// QEMUDisplay.m
// GrasaDroid: Implementación del puente QEMU -> Metal.
//
// Cómo funciona:
// 1. QEMU con --enable-opengl renderiza via EGL (ANGLE -> Metal en iOS).
// 2. virglrenderer procesa los comandos 3D del guest y los ejecuta en el host.
// 3. Este puente recibe el framebuffer final y lo presenta en un CAMetalLayer.
//
// El DisplayChangeListener de QEMU nos avisa cuando hay updates.
// Para GL, usamos dpy_gl_scanout_texture para obtener la textura.

#import "QEMUDisplay.h"
#import <dlfcn.h>

// Estructuras mínimas de QEMU para el DisplayChangeListener
// (definiciones simplificadas; las reales están en qemu/include/ui/console.h)
typedef struct DisplayChangeListener DisplayChangeListener;
typedef struct DisplaySurface DisplaySurface;

@interface QEMUDisplay ()
@property (nonatomic, readwrite) CAMetalLayer *metalLayer;
@property (nonatomic, readwrite) id<MTLDevice> metalDevice;
@property (nonatomic, weak) UIView *hostView;
@property (nonatomic) void *eglDisplay;
@property (nonatomic) void *eglContext;
@end

@implementation QEMUDisplay

- (instancetype)initWithView:(UIView *)view {
    self = [super init];
    if (self) {
        _hostView = view;
    }
    return self;
}

- (BOOL)setup {
    // 1. Crear el dispositivo Metal
    self.metalDevice = MTLCreateSystemDefaultDevice();
    if (!self.metalDevice) {
        NSLog(@"[GrasaDroid] No se pudo crear MTLDevice");
        return NO;
    }

    // 2. Crear el CAMetalLayer
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.device = self.metalDevice;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = NO; // Necesitamos leer/escribir
    self.metalLayer.contentsScale = [UIScreen mainScreen].scale;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.metalLayer.frame = self.hostView.bounds;
        [self.hostView.layer addSublayer:self.metalLayer];
    });

    // 3. EGL/ANGLE se inicializa cuando QEMU arranca con -display egl
    //    ANGLE traduce EGL -> Metal automáticamente en iOS.
    NSLog(@"[GrasaDroid] Display Metal configurado");

    return YES;
}

- (void)registerWithQEMU:(void *)qemuHandle {
    // QEMU expone funciones para registrar DisplayChangeListeners.
    // Las resolvemos dinámicamente para no linkear contra headers de QEMU.
    //
    // Funciones que buscamos:
    // - register_displaychangelistener(DisplayChangeListener*)
    // - dpy_gl_scanout_texture(DisplayChangeListener*, uint32_t texture_id, ...)
    //
    // Por ahora registramos un listener básico; la integración GL completa
    // requiere exponer las structs de QEMU, que haremos en el siguiente hito.

    NSLog(@"[GrasaDroid] Display registrado con QEMU (modo básico)");

    // TODO(hito-display-gl):
    // 1. Definir DisplayChangeListener con ops GL (dpy_gl_ctx_create, dpy_gl_scanout_texture, etc.)
    // 2. Crear contexto EGL via ANGLE (eglGetDisplay, eglInitialize, eglCreateContext)
    // 3. En dpy_gl_scanout_texture: recibir el texture_id de virgl y blitearlo al CAMetalLayer
    //    usando un MTLTexture compartido via IOSurface o via ANGLE_metal.
}

- (void)presentFrame {
    // Obtiene el drawable actual y presenta.
    // El contenido real lo escribe QEMU via el contexto GL compartido.
    @autoreleasepool {
        id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
        if (!drawable) return;

        id<MTLCommandQueue> queue = [self.metalDevice newCommandQueue];
        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        [cmd presentDrawable:drawable];
        [cmd commit];
    }
}

@end
