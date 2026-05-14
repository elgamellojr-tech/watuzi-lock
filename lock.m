#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Importamos las funciones de Cydia Substrate
#include <substrate.h>

// --- Hook para WAChatViewController ---
static void (*orig_WAChatViewController_viewWillAppear)(id, SEL, BOOL);
void replaced_WAChatViewController_viewWillAppear(id self, SEL _cmd, BOOL animated) {
    orig_WAChatViewController_viewWillAppear(self, _cmd, animated);
    
    // Obtenemos la Navigation Bar
    UINavigationController *navController = [self performSelector:@selector(navigationController)];
    UINavigationBar *navBar = navController.navigationBar;
    
    // Transparencia total
    [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navBar setShadowImage:[UIImage new]];
    [navBar setTranslucent:YES];
    [navBar setBackgroundColor:[UIColor clearColor]];
    
    // Extender el layout
    [(UIViewController *)self setEdgesForExtendedLayout:UIRectEdgeAll];
    [(UIViewController *)self setExtendedLayoutIncludesOpaqueBars:YES];
}

// --- Hook para WAMessageInputView ---
static void (*orig_WAMessageInputView_layoutSubviews)(id, SEL);
void replaced_WAMessageInputView_layoutSubviews(id self, SEL _cmd) {
    orig_WAMessageInputView_layoutSubviews(self, _cmd);
    
    UIView *inputView = (UIView *)self;
    [inputView setBackgroundColor:[UIColor clearColor]];
    [inputView setOpaque:NO];

    // Ocultar capas de fondo/blur
    for (UIView *subview in inputView.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
            [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
            [subview setHidden:YES];
            [subview setAlpha:0.0];
        }
    }
}

// --- Constructor (Se ejecuta al cargar el dylib) ---
__attribute__((constructor))
static void initialize() {
    // Hooking WAChatViewController
    MSHookMessageEx(NSClassFromString(@"WAChatViewController"), 
                    @selector(viewWillAppear:), 
                    (IMP)replaced_WAChatViewController_viewWillAppear, 
                    (IMP *)&orig_WAChatViewController_viewWillAppear);
    
    // Hooking WAMessageInputView
    MSHookMessageEx(NSClassFromString(@"WAMessageInputView"), 
                    @selector(layoutSubviews), 
                    (IMP)replaced_WAMessageInputView_layoutSubviews, 
                    (IMP *)&orig_WAMessageInputView_layoutSubviews);
}
