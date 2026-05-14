#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// BYPASS GLOBAL DIRECTO A LAS VARIABLES INTERNAS
// ============================================================================

// Fuerza a cualquier método booleano de Watusi a retornar SIEMPRE verdadero o falso según corresponda
BOOL hook_ReturnYES(id self, SEL _cmd) { return YES; }
BOOL hook_ReturnNO(id self, SEL _cmd) { return NO; }
CGFloat hook_ReturnZero(id self, SEL _cmd) { return 0.0; }

// Interceptamos el constructor original de WatusiManager
static id (*original_WatusiManager_init)(id, SEL);

id custom_WatusiManager_init(id self, SEL _cmd) {
    self = original_WatusiManager_init(self, _cmd);
    if (self) {
        // Forzamos las variables de instancia internas (ivars) si existen
        NSArray *ivars = @[@"_isPurchased", @"_adsRemoved", @"_isAdFree", @"_premium"];
        for (NSString *ivarName in ivars) {
            Ivar ivar = class_getInstanceVariable([self class], [ivarName UTF8String]);
            if (ivar) {
                // Setea el valor booleano directamente en la dirección de memoria del objeto (YES = 1)
                BOOL premiumValue = YES;
                object_setIvar(self, ivar, (id)@(premiumValue));
            }
        }
    }
    return self;
}

// Ocultación total de las subvistas de anuncios
void hook_ForceHideAdView(id self, SEL _cmd) {
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.alpha = 0.0;
    [view initWithFrame:CGRectZero];
    for (UIView *subview in view.subviews) {
        [subview removeFromSuperview];
    }
}

// ============================================================================
// CONSTRUCTOR CENTRAL (INYECTOR ANTIANUNCIOS AVANZADO)
// ============================================================================
__attribute__((constructor)) static void initWatusiAntiAdsAdvanced() {
    
    Class watusiManager = NSClassFromString(@"WatusiManager");
    if (watusiManager) {
        // 1. Swizzling del init para forzar variables internas en memoria
        Method origInitMethod = class_getInstanceMethod(watusiManager, @selector(init));
        if (origInitMethod) {
            original_WatusiManager_init = (void *)method_getImplementation(origInitMethod);
            method_setImplementation(origInitMethod, (IMP)custom_WatusiManager_init);
        }
        
        // 2. Lista masiva de selectores de compra posibles en Watusi (viejos y nuevos)
        NSArray *selectorsYES = @[@"isPurchased", @"adsRemoved", @"isAdFree", @"isPremium", @"purchased"];
        for (NSString *selName in selectorsYES) {
            class_replaceMethod(watusiManager, NSSelectorFromString(selName), (IMP)hook_ReturnYES, "B@:");
        }
        
        NSArray *selectorsNO = @[@"shouldShowAds", @"showAds", @"displayAds", @"bannerEnabled"];
        for (NSString *selName in selectorsNO) {
            class_replaceMethod(watusiManager, NSSelectorFromString(selName), (IMP)hook_ReturnNO, "B@:");
        }
    }
    
    // 3. Bloqueo físico de celdas y contenedores de publicidad (Cualquier remanente visual)
    NSArray *adClasses = @[
        @"WatusiAdCell", @"WATAdCell", 
        @"WatusiBannerView", @"WATAdBannerRow", 
        @"WatusiMediaAdView", @"WATAdView",
        @"FBRewardedVideoAd", @"GADBannerView", // Bloquea también si usa Facebook Ads o Google AdMob nativo
        @"GADInAppPurchase", @"GADMAdNetworkConnector"
    ];
    
    for (NSString *className in adClasses) {
        Class targetAdClass = NSClassFromString(className);
        if (targetAdClass) {
            // Quitamos la altura por completo
            class_replaceMethod(targetAdClass, NSSelectorFromString(@"cellHeight"), (IMP)hook_ReturnZero, "d@:");
            class_replaceMethod(targetAdClass, NSSelectorFromString(@"desiredHeight"), (IMP)hook_ReturnZero, "d@:");
            class_replaceMethod(targetAdClass, NSSelectorFromString(@"height"), (IMP)hook_ReturnZero, "d@:");
            
            // Forzamos a que si la vista intenta dibujarse, se autodestruya
            class_replaceMethod(targetAdClass, @selector(layoutSubviews), (IMP)hook_ForceHideAdView, "v@:");
            class_replaceMethod(targetAdClass, @selector(didMoveToWindow), (IMP)hook_ForceHideAdView, "v@:");
        }
    }
}
