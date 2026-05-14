#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface TransparentHook : NSObject
@end

@implementation TransparentHook

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 1. Hook para la barra superior y extender el layout al chat
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
        
        id newViewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            
            UIViewController *vc = (UIViewController *)self;
            UINavigationBar *navBar = vc.navigationController.navigationBar;
            
            // Barra superior transparente
            [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [navBar setShadowImage:[UIImage new]];
            [navBar setTranslucent:YES];
            [navBar setBackgroundColor:[UIColor clearColor]];
            
            // Forzar que el chat ocupe TODA la pantalla (detrás de las barras)
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;

            // Hacer que la tabla de mensajes sea transparente
            if ([vc respondsToSelector:@selector(tableView)]) {
                UITableView *tableView = [vc performSelector:@selector(tableView)];
                tableView.backgroundColor = [UIColor clearColor];
                tableView.backgroundView = nil;
            }
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // 2. Hook para la barra de escritura (WAMessageInputView)
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayoutMethod = class_getInstanceMethod(inputClass, layoutSel);
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayoutMethod);
        
        id newLayoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            
            UIView *inputView = (UIView *)self;
            [inputView setBackgroundColor:[UIColor clearColor]];
            [inputView setOpaque:NO];
            
            // Eliminar fondos de sistema (Blur/Grises)
            for (UIView *subview in inputView.subviews) {
                if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    [subview setHidden:YES];
                    [subview setAlpha:0.0];
                }
            }
        };
        method_setImplementation(origLayoutMethod, imp_implementationWithBlock(newLayoutBlock));

        // 3. Hook para eliminar el color de fondo por defecto del chat
        Class wallpaperClass = NSClassFromString(@"WAWallpaperView");
        SEL wallSel = @selector(layoutSubviews);
        Method origWallMethod = class_getInstanceMethod(wallpaperClass, wallSel);
        void (*origWallImp)(id, SEL) = (void *)method_getImplementation(origWallMethod);

        id newWallBlock = ^(id self) {
            origWallImp(self, wallSel);
            [(UIView *)self setBackgroundColor:[UIColor clearColor]];
            [(UIView *)self setAlpha:1.0]; // Asegura que no se oculte el wallpaper
        };
        method_setImplementation(origWallMethod, imp_implementationWithBlock(newWallBlock));
    });
}

@end
