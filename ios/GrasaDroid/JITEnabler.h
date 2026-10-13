//
//  JITEnabler.h
//  GrasaDroid
//
//  Habilita JIT mediante self-debugging: un proceso helper se adjunta
//  como debugger al proceso principal usando PT_ATTACH. iOS permite
//  MAP_JIT solo cuando el proceso está siendo depurado (flag P_TRACED).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JITEnabler : NSObject

/// Intenta habilitar JIT mediante self-debugging.
/// Retorna YES si el proceso quedó marcado como depurado.
/// Debe llamarse temprano en el arranque de la app.
+ (BOOL)enableJIT;

/// Verifica si JIT está disponible ahora mismo (prueba MAP_JIT real).
+ (BOOL)isJITAvailable;

/// Detiene el helper de debugging (llamar al salir, opcional).
+ (void)disableJIT;

@end

NS_ASSUME_NONNULL_END
