#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Declaraciones para evitar advertencias de compilación
@interface UIView (Reva)
- (void)setTailStyle:(NSInteger)style;
@end

static void (*orig_layoutSubviews)(UIView *, SEL);

static void hooked_layoutSubviews(UIView *self, SEL _cmd) {
    // Llamada al método original
    orig_layoutSubviews(self, _cmd);

    if ([NSStringFromClass([self class]) isEqualToString:@"WABubbleView"]) {
        
        // Detectar si es enviado o recibido por posición
        BOOL isOutgoing = (self.frame.origin.x > 60);
        
        // Estilo Reva UI
        self.layer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
        self.layer.borderWidth = 1.6;
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;

        if (isOutgoing) {
            // Adaptable al color del tema (tintColor)
            self.layer.borderColor = self.tintColor.CGColor;
        } else {
            self.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.5].CGColor;
        }

        // Quitar la cola (Tail) del mensaje
        if ([self respondsToSelector:@selector(setTailStyle:)]) {
            [self setTailStyle:0];
        }
    }
}

// Constructor que se ejecuta al cargar el dylib
__attribute__((constructor))
static void init() {
    Class targetClass = objc_getClass("WABubbleView");
    if (targetClass) {
        Method method = class_getInstanceMethod(targetClass, @selector(layoutSubviews));
        orig_layoutSubviews = (void *)method_getImplementation(method);
        method_setImplementation(method, (IMP)hooked_layoutSubviews);
    }
}
