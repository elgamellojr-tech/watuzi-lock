#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface GlobalRedText : NSObject
@end

@implementation GlobalRedText

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // --- 1. HOOK GLOBAL PARA TODOS LOS UILABEL ---
        Class labelClass = [UILabel class];
        SEL setTextColorSel = @selector(setTextColor:);
        Method origMethod = class_getInstanceMethod(labelClass, setTextColorSel);
        void (*origImp)(id, SEL, UIColor *) = (void *)method_getImplementation(origMethod);
        
        id redTextBlock = ^(id self, UIColor *color) {
            // Forzamos rojo puro en cada etiqueta de la app
            origImp(self, setTextColorSel, [UIColor redColor]);
        };
        method_setImplementation(origMethod, imp_implementationWithBlock(redTextBlock));

        // --- 2. HOOK PARA TEXTO ATRIBUIDO (Mensajes con formato) ---
        // Algunos chats usan texto con formato (negritas, enlaces), esto los captura
        SEL setAttributedTextSel = @selector(setAttributedText:);
        Method origAttrMethod = class_getInstanceMethod(labelClass, setAttributedTextSel);
        void (*origAttrImp)(id, SEL, NSAttributedString *) = (void *)method_getImplementation(origAttrMethod);

        id redAttrTextBlock = ^(id self, NSAttributedString *attrStr) {
            if (attrStr) {
                NSMutableAttributedString *mStr = [attrStr mutableCopy];
                [mStr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, mStr.length)];
                origAttrImp(self, setAttributedTextSel, mStr);
            } else {
                origAttrImp(self, setAttributedTextSel, attrStr);
            }
        };
        method_setImplementation(origAttrMethod, imp_implementationWithBlock(redAttrTextBlock));

        // --- 3. HOOK DE TINTE GLOBAL (Iconos y Botones) ---
        Class windowClass = [UIWindow class];
        SEL setTintSel = @selector(setTintColor:);
        Method origTintMethod = class_getInstanceMethod(windowClass, setTintSel);
        void (*origTintImp)(id, SEL, UIColor *) = (void *)method_getImplementation(origTintMethod);

        id redTintBlock = ^(id self, UIColor *color) {
            origTintImp(self, setTintSel, [UIColor redColor]);
        };
        method_setImplementation(origTintMethod, imp_implementationWithBlock(redTintBlock));
        
        // --- 4. PREVENIR QUE WHATSAPP SOBREESCRIBA EL COLOR EN CHATS ---
        // Hookeamos la celda de mensaje para asegurar el color rojo al final del renderizado
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        SEL layoutSel = @selector(layoutSubviews);
        Method origCellMethod = class_getInstanceMethod(cellClass, layoutSel);
        void (*origCellImp)(id, SEL) = (void *)method_getImplementation(origCellMethod);

        id cellBlock = ^(id self) {
            origCellImp(self, layoutSel);
            UIView *view = (UIView *)self;
            // Buscamos todas las etiquetas dentro de la burbuja y las pintamos de rojo
            for (UILabel *lbl in [view valueForKeyPath:@"subviews"]) {
                if ([lbl isKindOfClass:[UILabel class]]) {
                    lbl.textColor = [UIColor redColor];
                }
            }
        };
        method_setImplementation(origCellMethod, imp_implementationWithBlock(cellBlock));
    });
}

@end
