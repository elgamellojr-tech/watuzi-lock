#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface Flex3FlotanteEngine : NSObject
@end

@implementation Flex3FlotanteEngine

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // --- PARCHE 1: BARRA SUPERIOR TRANSPARENTE ---
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
        
        id newViewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            UIViewController *vc = (UIViewController *)self;
            UINavigationBar *nb = vc.navigationController.navigationBar;
            [nb setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [nb setShadowImage:[UIImage new]];
            [nb setTranslucent:YES];
            [nb setBackgroundColor:[UIColor clearColor]];
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // --- PARCHE 2: BURBUJAS REVA (BORDE VERDE) ---
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayout = class_getInstanceMethod(cellClass, layoutSel);
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayout);

        id layoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            UIView *cell = (UIView *)self;
            for (UIView *subview in cell.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"Bubble"] || [NSStringFromClass([subview class]) containsString:@"Container"]) {
                    subview.backgroundColor = [UIColor clearColor];
                    subview.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0].CGColor;
                    subview.layer.borderWidth = 1.5;
                    subview.layer.cornerRadius = 18.0;
                    for (UIView *inner in subview.subviews) { if ([inner isKindOfClass:[UIImageView class]]) inner.hidden = YES; }
                }
            }
        };
        method_setImplementation(origLayout, imp_implementationWithBlock(layoutBlock));

        // --- PARCHE 3: BARRA DE ESCRITURA FLOTANTE ---
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL inLayoutSel = @selector(layoutSubviews);
        Method origInMethod = class_getInstanceMethod(inputClass, inLayoutSel);
        void (*origInImp)(id, SEL) = (void *)method_getImplementation(origInMethod);

        id newInBlock = ^(id self) {
            origInImp(self, inLayoutSel);
            UIView *inputV = (UIView *)self;
            
            // 1. Transparencia total del contenedor base
            inputV.backgroundColor = [UIColor clearColor];
            for (UIView *sub in inputV.subviews) {
                if ([sub isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || [sub isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    sub.hidden = YES;
                }
            }

            // 2. Hacer que el campo de texto flote
            // Ajustamos el diseño para que no pegue a los bordes
            CGRect frame = inputV.frame;
            inputV.layer.cornerRadius = 25.0; // Bordes muy redondeados
            inputV.layer.masksToBounds = NO;
            
            // 3. Añadir sombra para efecto de elevación (Flotante)
            inputV.layer.shadowColor = [UIColor blackColor].CGColor;
            inputV.layer.shadowOffset = CGSizeMake(0, -2);
            inputV.layer.shadowRadius = 10.0;
            inputV.layer.shadowOpacity = 0.3;
            
            // 4. Borde verde para combinar con Reva UI
            inputV.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:0.8].CGColor;
            inputV.layer.borderWidth = 1.0;
            
            // Aplicar un margen interno para que se vea despegado de los lados
            if (inputV.superview) {
                CGRect parentFrame = inputV.superview.bounds;
                inputV.frame = CGRectMake(10, frame.origin.y - 5, parentFrame.size.width - 20, frame.size.height);
            }
        };
        method_setImplementation(origInMethod, imp_implementationWithBlock(newInBlock));
    });
}

@end
