// QEMUDisplay.h
// GrasaDroid: Puente de display QEMU -> Metal.
// Recibe los frames de QEMU (vía DisplayChangeListener con OpenGL/virgl)
// y los presenta en un CAMetalLayer.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface QEMUDisplay : NSObject

- (instancetype)initWithView:(UIView *)view;

/// Configura el CAMetalLayer y el contexto EGL/ANGLE.
/// Retorna YES si todo está listo.
- (BOOL)setup;

/// Registra este display con QEMU usando las funciones de la librería cargada.
- (void)registerWithQEMU:(void *)qemuHandle;

/// Llamado por QEMU cuando hay un nuevo frame disponible.
- (void)presentFrame;

@property (nonatomic, readonly) CAMetalLayer *metalLayer;
@property (nonatomic, readonly) id<MTLDevice> metalDevice;

@end

NS_ASSUME_NONNULL_END
