#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RevaUIUltra : NSObject
@end

@implementation RevaUIUltra

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // --- 1. HOOK PARA ELIMINAR EL FONDO DE LAS BURBUJAS ---
        // Hookeamos el método que configura el fondo de la burbuja
        Class bubbleViewClass = NSClassFromString(@"WBBubbleView") ?: NSClassFromString(@"WABubbleView");
        if (bubbleViewClass) {
            SEL setBgSel = @selector(setBackgroundColor:);
            Method origSetBg = class_getInstanceMethod(bubbleViewClass, setBgSel);
            id bgBlock = ^(id self, UIColor *color) {
                // Forzamos que cualquier intento de poner color sea transparente
                ((void (*)(id, SEL, UIColor *))method_getImplementation(origSetBg))(self, setBgSel, [UIColor clearColor]);
            };
            method_setImplementation(origSetBg, imp_implementationWithBlock(bgBlock));
        }

        // --- 2. APLICAR BORDE VERDE Y TRANSPARENCIA EN LA CELDA ---
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayout = class_getInstanceMethod(cellClass, layoutSel);
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayout);

        id layoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            
            UIView *cell = (UIView *)self;
            cell.backgroundColor = [UIColor clearColor];

            // Buscamos la burbuja dentro de la celda
            for (UIView *subview in cell.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"Bubble"] || 
                    [NSStringFromClass([subview class]) containsString:@"Container"]) {
                    
                    subview.backgroundColor = [UIColor clearColor];
                    subview.layer.backgroundColor = [UIColor clearColor].CGColor;
                    
                    // Estilo Reva: Borde verde neón y esquinas redondeadas
                    subview.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0].CGColor;
                    subview.layer.borderWidth = 1.5;
                    subview.layer.cornerRadius = 18.0;
                    subview.layer.masksToBounds = YES;

                    // Ocultar cualquier imagen (la burbuja original de WA)
                    for (UIView *inner in subview.subviews) {
                        if ([inner isKindOfClass:[UIImageView class]]) {
                            inner.hidden = YES;
                        }
                    }
                }
            }
        };
        method_setImplementation(origLayout, imp_implementationWithBlock(layoutBlock));

        // --- 3. BARRAS TOTALMENTE TRANSPARENTES (NAV & INPUT) ---
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origView = class_getInstanceMethod(chatClass, viewSel);
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origView);

        id viewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            UIViewController *vc = (UIViewController *)self;
            
            // Transparencia arriba
            UINavigationBar *nb = vc.navigationController.navigationBar;
            [nb setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [nb setShadowImage:[UIImage new]];
            [nb setTranslucent:YES];
            [nb setBackgroundColor:[UIColor clearColor]];
            
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;
        };
        method_setImplementation(origView, imp_implementationWithBlock(viewBlock));

        // Transparencia abajo (Barra de escribir)
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL inLayoutSel = @selector(layoutSubviews);
        Method origInLayout = class_getInstanceMethod(inputClass, inLayoutSel);
        void (*origInImp)(id, SEL) = (void *)method_getImplementation(origInLayout);

        id inBlock = ^(id self) {
            origInImp(self, inLayoutSel);
            UIView *inV = (UIView *)self;
            inV.backgroundColor = [UIColor clearColor];
            for (UIView *s in inV.subviews) {
                if ([s isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [s isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    s.hidden = YES;
                }
            }
        };
        method_setImplementation(origInLayout, imp_implementationWithBlock(inBlock));
    });
}
@end
