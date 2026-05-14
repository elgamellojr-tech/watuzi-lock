#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RevaGreenFinal : NSObject
@end

@implementation RevaGreenFinal

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 1. Hook para Nav Bar y Extensión (Nombre de contacto y fondo total)
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
            
            // Forzar tabla transparente
            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tv = [vc performSelector:@selector(tableView)];
                tv.backgroundColor = [UIColor clearColor];
                tv.backgroundView = nil;
            }
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // 2. Hook para Burbujas (Fondo Transparente + Borde Verde)
        // Usamos WAMessageChatTableViewCell que es la clase base de las burbujas
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        SEL layoutSel = @selector(layoutSubviews);
        Method origCellMethod = class_getInstanceMethod(cellClass, layoutSel);
        void (*origCellImp)(id, SEL) = (void *)method_getImplementation(origCellMethod);

        id newCellBlock = ^(id self) {
            origCellImp(self, layoutSel);
            UIView *cell = (UIView *)self;
            
            // Recorremos las subvistas para encontrar la burbuja (BubbleView)
            for (UIView *subview in cell.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"BubbleView"] || 
                    [NSStringFromClass([subview class]) containsString:@"Container"]) {
                    
                    subview.backgroundColor = [UIColor clearColor];
                    subview.layer.backgroundColor = [UIColor clearColor].CGColor;
                    
                    // Aplicar borde verde estilo Reva UI
                    subview.layer.borderColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.35 alpha:1.0].CGColor;
                    subview.layer.borderWidth = 1.2;
                    subview.layer.cornerRadius = 14.0;
                    subview.layer.masksToBounds = YES;
                    
                    // Eliminar cualquier imagen de fondo (la burbuja original de WhatsApp es una imagen)
                    for (UIView *subsub in subview.subviews) {
                        if ([subsub isKindOfClass:[UIImageView class]]) {
                            subsub.hidden = YES;
                        }
                    }
                }
            }
        };
        method_setImplementation(origCellMethod, imp_implementationWithBlock(newCellBlock));

        // 3. Hook para Input Bar (Barra de escribir)
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL inLayoutSel = @selector(layoutSubviews);
        Method origInMethod = class_getInstanceMethod(inputClass, inLayoutSel);
        void (*origInImp)(id, SEL) = (void *)method_getImplementation(origInMethod);

        id newInBlock = ^(id self) {
            origInImp(self, inLayoutSel);
            UIView *view = (UIView *)self;
            view.backgroundColor = [UIColor clearColor];
            for (UIView *sub in view.subviews) {
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
