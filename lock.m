#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface TransparentHook : NSObject
@end

@implementation TransparentHook

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Hook para la barra superior (WAChatViewController)
        Class chatClass = NSClassFromString(@"WAChatViewController");
        SEL viewSel = @selector(viewWillAppear:);
        Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
        
        void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
        
        id newViewBlock = ^(id self, BOOL animated) {
            origViewImp(self, viewSel, animated);
            
            UIViewController *vc = (UIViewController *)self;
            UINavigationBar *navBar = vc.navigationController.navigationBar;
            
            // Hacer transparente la barra de arriba
            [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [navBar setShadowImage:[UIImage new]];
            [navBar setTranslucent:YES];
            [navBar setBackgroundColor:[UIColor clearColor]];
            
            // Expandir el fondo del chat detrás de las barras
            vc.edgesForExtendedLayout = UIRectEdgeAll;
            vc.extendedLayoutIncludesOpaqueBars = YES;
        };
        
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // Hook para la barra de escritura (WAMessageInputView)
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayoutMethod = class_getInstanceMethod(inputClass, layoutSel);
        
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayoutMethod);
        
        id newLayoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            
            UIView *inputView = (UIView *)self;
            [inputView setBackgroundColor:[UIColor clearColor]];
            [inputView setOpaque:NO];
            
            // Quitar el blur y fondos grises de la barra de escribir
            for (UIView *subview in inputView.subviews) {
                if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    [subview setHidden:YES];
                    [subview setAlpha:0.0];
                }
            }
        };
        
        method_setImplementation(origLayoutMethod, imp_implementationWithBlock(newLayoutBlock));
    });
}

@end
