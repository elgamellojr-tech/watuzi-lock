#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RevaUIFinalV2 : NSObject
@end

@implementation RevaUIFinalV2

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 1. FORZAR TRANSPARENCIA EN BARRAS (SUPERIOR E INFERIOR)
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
        
        id newViewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            UIViewController *vc = (UIViewController *)self;
            
            UINavigationBar *navBar = vc.navigationController.navigationBar;
            [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [navBar setShadowImage:[UIImage new]];
            [navBar setTranslucent:YES];
            [navBar setBackgroundColor:[UIColor clearColor]];
            
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;

            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tv = [vc performSelector:@selector(tableView)];
                tv.backgroundColor = [UIColor clearColor];
                tv.backgroundView = nil;
            }
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // 2. ESTILO DE BURBUJAS REVA (BORDE VERDE + TRANSPARENCIA REAL)
        // Probamos con la clase base de la celda de mensaje
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        SEL layoutSel = @selector(layoutSubviews);
        Method origCellMethod = class_getInstanceMethod(cellClass, layoutSel);
        void (*origCellImp)(id, SEL) = (void *)method_getImplementation(origCellMethod);

        id newCellBlock = ^(id self) {
            origCellImp(self, layoutSel);
            UIView *cell = (UIView *)self;
            
            // Buscamos profundamente en todas las subvistas
            for (UIView *subview in cell.subviews) {
                // Buscamos cualquier vista que contenga la burbuja (Bubble o Container)
                if ([NSStringFromClass([subview class])兴奋String:@"Bubble"] || 
                    [NSStringFromClass([subview class]) containsString:@"Container"]) {
                    
                    subview.backgroundColor = [UIColor clearColor];
                    subview.layer.backgroundColor = [UIColor clearColor].CGColor;
                    
                    // Aplicar el borde verde característico de Reva
                    subview.layer.borderColor = [UIColor colorWithRed:0.0 green:0.9 blue:0.4 alpha:1.0].CGColor;
                    subview.layer.borderWidth = 1.4;
                    subview.layer.cornerRadius = 16.0;
                    subview.layer.masksToBounds = YES;
                    
                    // ELIMINAR EL DIBUJO ORIGINAL DE WHATSAPP
                    // Esto oculta las imágenes de las burbujas que tapan el fondo
                    for (UIView *innerView in subview.subviews) {
                        if ([innerView isKindOfClass:[UIImageView class]]) {
                            innerView.hidden = YES;
                        }
                        // Si la burbuja es una vista de dibujo especial
                        if ([NSStringFromClass([innerView class]) containsString:@"Shape"]) {
                            innerView.hidden = YES;
                        }
                    }
                }
            }
        };
        method_setImplementation(origCellMethod, imp_implementationWithBlock(newCellBlock));

        // 3. BARRA DE ESCRITURA TOTALMENTE INVISIBLE
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL inLayoutSel = @selector(layoutSubviews);
        Method origInMethod = class_getInstanceMethod(inputClass, inLayoutSel);
        void (*origInImp)(id, SEL) = (void *)method_getImplementation(origInMethod);

        id newInBlock = ^(id self) {
            origInImp(self, inLayoutSel);
            UIView *view = (UIView *)self;
            view.backgroundColor = [UIColor clearColor];
            
            for (UIView *sub in view.subviews) {
                // Removemos el fondo gris y el blur
                if ([sub isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [sub isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    sub.hidden = YES;
                }
            }
        };
        method_setImplementation(origInMethod, imp_implementationWithBlock(newInBlock));
    });
}

@end
