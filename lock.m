#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RedTextEngine : NSObject
@end

@implementation RedTextEngine

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // --- PARCHE GLOBAL: CAMBIAR TODOS LOS TEXTOS A ROJO ---
        // Interceptamos UILabel, que es la base de casi todo el texto en iOS
        Class labelClass = [UILabel class];
        SEL setTextColorSel = @selector(setTextColor:);
        Method origMethod = class_getInstanceMethod(labelClass, setTextColorSel);
        
        // Guardamos la implementación original
        void (*origImp)(id, SEL, UIColor *) = (void *)method_getImplementation(origMethod);
        
        // Creamos la nueva lógica
        id redTextBlock = ^(id self, UIColor *color) {
            // Forzamos el color rojo puro
            UIColor *redColor = [UIColor redColor];
            
            // Llamamos a la implementación original pero siempre pasando nuestro color rojo
            origImp(self, setTextColorSel, redColor);
        };
        
        // Aplicamos el cambio al sistema
        method_setImplementation(origMethod, imp_implementationWithBlock(redTextBlock));

        // --- PARCHE ADICIONAL: PARA LOS BOTONES Y TINTES (OPCIONAL) ---
        // Esto asegura que los iconos y botones de navegación también se vean rojos
        Class windowClass = [UIWindow class];
        SEL setTintSel = @selector(setTintColor:);
        Method origTintMethod = class_getInstanceMethod(windowClass, setTintSel);
        void (*origTintImp)(id, SEL, UIColor *) = (void *)method_getImplementation(origTintMethod);

        id redTintBlock = ^(id self, UIColor *color) {
            origTintImp(self, setTintSel, [UIColor redColor]);
        };
        method_setImplementation(origTintMethod, imp_implementationWithBlock(redTintBlock));
    });
}

@end
