/*
  -------------------------------------------------------------------------
  MODELO DE PATCH.PLIST (ESTILO FLEX 3 JAILBREAK)
  -------------------------------------------------------------------------
  <dict>
    <key>Name</key> <string>WhatsApp Reva UI Transparent</string>
    <key>Author</key> <string>iOS DOMIDIOS</string>
    <key>Units</key>
    <array>
      <dict>
        <key>MethodObjc</key> <dict><key>ClassName</key><string>WAChatViewController</string><key>Selector</key><string>viewWillAppear:</string></dict>
        <key>Action</key> <string>Force Transparent Navigation Bar</string>
      </dict>
      <dict>
        <key>MethodObjc</key> <dict><key>ClassName</key><string>WAMessageChatTableViewCell</string><key>Selector</key><string>layoutSubviews</string></dict>
        <key>Action</key> <string>Set Bubble Background 0.0 & Border Green</string>
      </dict>
    </array>
  </dict>
  -------------------------------------------------------------------------
*/

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface Flex3Engine : NSObject
@end

@implementation Flex3Engine

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // --- PARCHE FLEX: TRANSPARENCIA DE BARRA SUPERIOR ---
        Class chatClass = NSClassFromString(@"WAChatViewController");
        if (chatClass) {
            SEL viewSel = @selector(viewWillAppear:);
            Method origViewMethod = class_getInstanceMethod(chatClass, viewSel);
            void (*origViewImp)(id, SEL, BOOL) = (void *)method_getImplementation(origViewMethod);
            
            id newViewBlock = ^(id self, BOOL animated) {
                origViewImp(self, viewSel, animated);
                
                UIViewController *vc = (UIViewController *)self;
                UINavigationBar *navBar = vc.navigationController.navigationBar;
                
                // Aplicando valores de parche Flex
                [navBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
                [navBar setShadowImage:[UIImage new]];
                [navBar setTranslucent:YES];
                [navBar setBackgroundColor:[UIColor clearColor]];
                
                vc.edgesForExtendedLayout = UIRectEdgeAll;
                vc.extendedLayoutIncludesOpaqueBars = YES;
            };
            method_setImplementation(origViewMethod, imp_implementationWithBlock(newViewBlock));
        }

        // --- PARCHE FLEX: BURBUJAS REVA (BORDE VERDE + TRANSPARENCIA) ---
        Class cellClass = NSClassFromString(@"WAMessageChatTableViewCell");
        if (cellClass) {
            SEL layoutSel = @selector(layoutSubviews);
            Method origLayoutMethod = class_getInstanceMethod(cellClass, layoutSel);
            void (*origLayoutImp)(id, SEL) = (void *)method_getImplementation(origLayoutMethod);

            id newLayoutBlock = ^(id self) {
                origLayoutImp(self, layoutSel);
                
                UIView *cell = (UIView *)self;
                for (UIView *subview in cell.subviews) {
                    // Detectando el contenedor de la burbuja
                    if ([NSStringFromClass([subview class]) containsString:@"Bubble"] || 
                        [NSStringFromClass([subview class]) containsString:@"Container"]) {
                        
                        // Forzando transparencia (Flex Unit: Background Alpha 0)
                        subview.backgroundColor = [UIColor clearColor];
                        subview.layer.backgroundColor = [UIColor clearColor].CGColor;
                        
                        // Forzando Borde Verde (Flex Unit: BorderColor Green)
                        subview.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0].CGColor;
                        subview.layer.borderWidth = 1.5;
                        subview.layer.cornerRadius = 16.0;
                        subview.layer.masksToBounds = YES;
                        
                        // Ocultando la imagen original de la burbuja de WhatsApp
                        for (UIView *inner in subview.subviews) {
                            if ([inner isKindOfClass:[UIImageView class]]) {
                                inner.hidden = YES;
                            }
                        }
                    }
                }
            };
            method_setImplementation(origLayoutMethod, imp_implementationWithBlock(newLayoutBlock));
        }

        // --- PARCHE FLEX: BARRA DE ENTRADA TRANSPARENTE ---
        Class inputClass = NSClassFromString(@"WAMessageInputView");
        if (inputClass) {
            SEL inSel = @selector(layoutSubviews);
            Method origInMethod = class_getInstanceMethod(inputClass, inSel);
            void (*origInImp)(id, SEL) = (void *)method_getImplementation(origInMethod);

            id newInBlock = ^(id self) {
                origInImp(self, inSel);
                UIView *inputV = (UIView *)self;
                inputV.backgroundColor = [UIColor clearColor];
                for (UIView *sub in inputV.subviews) {
                    if ([sub isKindOfClass:NSClassFromString(@"UIVisualEffectView")] || 
                        [sub isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                        sub.hidden = YES;
                    }
                }
            };
            method_setImplementation(origInMethod, imp_implementationWithBlock(newInBlock));
        }
    });
}

@end
