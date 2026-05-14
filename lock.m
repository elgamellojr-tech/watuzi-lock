#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Función para aplicar el estilo Reva a una vista
static void applyRevaStyle(UIView *view, BOOL isOutgoing) {
    view.layer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    view.layer.borderWidth = 1.6;
    view.layer.cornerRadius = 14;
    view.layer.masksToBounds = YES;

    if (isOutgoing) {
        // Borde color del tema para enviados
        view.layer.borderColor = view.tintColor.CGColor;
    } else {
        // Borde gris suave para recibidos
        view.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.5].CGColor;
    }

    // Intentar quitar la cola (tail) si existe el método
    if ([view respondsToSelector:NSSelectorFromString(@"setTailStyle:")]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [view performSelector:NSSelectorFromString(@"setTailStyle:") withObject:0];
        #pragma clang diagnostic pop
    }
}

static void (*orig_layoutSubviews)(UITableViewCell *, SEL);

static void hooked_layoutSubviews(UITableViewCell *self, SEL _cmd) {
    orig_layoutSubviews(self, _cmd);

    // Buscamos la burbuja dentro de la celda del chat
    // Normalmente las clases de WhatsApp empiezan con 'WA'
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"MessageCell"]) {
        for (UIView *subview in self.contentView.subviews) {
            // Buscamos la vista que contiene el mensaje (la burbuja)
            if ([NSStringFromClass([subview class]) containsString:@"BubbleView"]) {
                BOOL isOutgoing = (subview.frame.origin.x > 60);
                applyRevaStyle(subview, isOutgoing);
            }
        }
    }
}

__attribute__((constructor))
static void init() {
    // Hookeamos la celda de mensaje, que es más estable que la burbuja sola
    Class targetClass = objc_getClass("WATextMessageCell");
    if (!targetClass) targetClass = objc_getClass("WAMessageChatTableViewCell");

    if (targetClass) {
        Method method = class_getInstanceMethod(targetClass, @selector(layoutSubviews));
        orig_layoutSubviews = (void *)method_getImplementation(method);
        method_setImplementation(method, (IMP)hooked_layoutSubviews);
    }
}
