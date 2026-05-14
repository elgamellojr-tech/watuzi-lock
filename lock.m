#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RevaGreenLock : NSObject
@end

@implementation RevaGreenLock

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // 1. Barras transparentes y extensión de pantalla
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
        };
        method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));

        // 2. Burbujas de mensaje: Fondo transparente y borde verde
        Class cellClass = NSClassFromString(@"WAChatMessageCell");
        SEL cellSel = @selector(layoutSubviews);
        Method origCellMethod = class_getInstanceMethod(cellClass, cellSel);
        void (*origCellImp)(id, SEL) = (void *)method_getImplementation(origCellMethod);

        id newCellBlock = ^(id self) {
            origCellImp(self, cellSel);
            
            UIView *cell = (UIView *)self;
            // Buscamos la vista del contenedor del mensaje (burbuja)
            for (UIView *subview in cell.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"MessageContainer"]) {
                    subview.backgroundColor = [UIColor clearColor];
                    subview.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0].CGColor; // Verde
                    subview.layer.borderWidth = 1.5;
                    subview.layer.cornerRadius = 12.0;
                    subview.clipsToBounds = YES;
                }
            }
        };
        method_setImplementation(origCellMethod, imp_implementationWithBlock(newCellBlock));

        // 3. Barra de escritura transparente
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        SEL layoutSel = @selector(layoutSubviews);
        Method origLayoutMethod = class_getInstanceMethod(inputClass, layoutSel);
        void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayoutMethod);
        
        id newLayoutBlock = ^(id self) {
            origLayoutImp(self, layoutSel);
            
            UIView *inputView = (UIView *)self;
            [inputView setBackgroundColor:[UIColor clearColor]];
            
            for (UIView *subview in inputView.subviews) {
                if ([subview isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                    [subview isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                    [subview setHidden:YES];
                }
            }
        };
        method_setImplementation(origLayoutMethod, imp_implementationWithBlock(newLayoutBlock));
    });
}

@end
