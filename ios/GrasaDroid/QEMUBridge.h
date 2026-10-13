// QEMUBridge.h
// GrasaDroid: Puente entre la app iOS y QEMU (libqemu-aarch64-softmmu.dylib)
// Ejecuta QEMU en un pthread separado y conecta el display a Metal.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, QEMUState) {
    QEMUStateStopped,
    QEMUStateStarting,
    QEMUStateRunning,
    QEMUStatePaused,
    QEMUStateError,
};

@protocol QEMUBridgeDelegate <NSObject>
- (void)qemuDidChangeState:(QEMUState)state;
- (void)qemuDidFailWithError:(NSString *)error;
@end

@interface QEMUBridge : NSObject

@property (nonatomic, weak) id<QEMUBridgeDelegate> delegate;
@property (nonatomic, readonly) QEMUState state;
@property (nonatomic, readonly) UIView *displayView;

+ (instancetype)shared;

/// Inicia QEMU con los parámetros dados.
/// @param args Argumentos de línea de comandos (sin el nombre del programa).
/// @param view Vista donde se renderizará la salida.
- (void)startWithArguments:(NSArray<NSString *> *)args
                      view:(UIView *)view;

/// Detiene QEMU.
- (void)stop;

/// Pausa/reanuda la emulación.
- (void)setPaused:(BOOL)paused;

@end

NS_ASSUME_NONNULL_END
