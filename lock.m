#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RevaUIFullLock : NSObject
@end

@implementation RevaUIFullLock

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 1. Hook para Barra Superior y Extensión de Fondo
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
        
        id newViewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            
            UIViewController *vc = (UIViewController *)self;
            UINavigationBar *navBar = vc.navigationController.navigationBar;
            
            // Hacer transparente la barra de navegación (nombre contacto)
            [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [navBar setShadowImage:[UIImage new]];
            [navBar setTranslucent:YES];
            [navBar setBackgroundColor:[UIColor clearColor]];
            
            // Extender el layout para que el fondo se vea sin límites (detrás de las barras)
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;

            // Transparencia en la tabla de mensajes
            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tableView = [vc performSelector:@selector(tableView)];
                [tableView setBackgroundColor:[UIColor clearColor]];
                [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
                [tableView setBackgroundView:nil];
            }
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // 2. Hook para Barra de Escritura (Input Bar)
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayoutMethod = class_getInstanceMethod(inputClass, layoutSel);
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayoutMethod);
        
        id newLayoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            
            UIView *inputView = (UIView *)self;
            [inputView setBackgroundColor:[UIColor clearColor]];
            [inputView setOpaque:NO];
            
            // Ocultar fondos del sistema y efectos de desenfoque (blur)
            for (UIView *subview in inputView.subviews) {
                if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    [subview setHidden:YES];
                    [subview setAlpha:0.0];
                }
            }
        };
        method_setImplementation(origLayoutMethod, imp_implementationWithBlock(newLayoutBlock));

        // 3. Hook para la Vista de Wallpaper (Asegurar transparencia total)
        Class wallpaperClass = NSClassFromString(@"WAWallpaperView");
        SEL wallSel = @selector(layoutSubviews);
        Method origWallMethod = class_getInstanceMethod(wallpaperClass, wallSel);
        void (*origWallImp)(id, SEL) = (void *)method_getImplementation(origWallMethod);

        id newWallBlock = ^(id self) {
            origWallImp(self, wallSel);
            [(UIView *)self setBackgroundColor:[UIColor clearColor]];
        };
        method_setImplementation(origWallMethod, imp_implementationWithBlock(newWallBlock));
    });
}

@end
