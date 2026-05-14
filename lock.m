#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// HOOKS LÓGICOS UNIVERSALES
// ============================================================================
BOOL hook_AlwaysYES(id self, SEL _cmd) { return YES; }
BOOL hook_AlwaysNO(id self, SEL _cmd) { return NO; }
CGFloat hook_AlwaysZero(id self, SEL _cmd) { return 0.0; }

// Bloquea llamadas que intentan descargar o pedir anuncios de la red
void hook_BlockAdRequest(id self, SEL _cmd, id request) { }
void hook_BlockVoid(id self, SEL _cmd) { }

// ============================================================================
// INTERCEPCIÓN AGRESIVA DE CONFIGURACIONES (NSUserDefaults)
// ============================================================================
static bool (*original_boolForKey)(id, SEL, NSString *);

bool custom_boolForKey(id self, SEL _cmd, NSString *defaultName) {
    // Si Watusi pregunta por cualquiera de estas llaves de configuración, le aseguramos que ya pagó
    if ([defaultName isEqualToString:@"WatusiPurchased"] || 
        [defaultName isEqualToString:@"WatusiAdsRemoved"] || 
        [defaultName isEqualToString:@"HideAds"] ||
        [defaultName isEqualToString:@"isAdFree"] ||
        [defaultName isEqualToString:@"PremiumEnabled"]) {
        return YES;
    }
    
    // Si pregunta si debe mostrar anuncios, le decimos rotundamente que NO
    if ([defaultName isEqualToString:@"ShowAds"] || 
        [defaultName isEqualToString:@"WatusiShowAds"]) {
        return NO;
    }
    
    return original_boolForKey(self, _cmd, defaultName);
}

// ============================================================================
// DESTRUCCIÓN DE VISTAS REMANENTES
// ============================================================================
void hook_CleanAdView(id self, SEL _cmd) {
    UIView *view = (UIView *)self;
    view.hidden = YES;
    view.alpha = 0.0;
    [view setFrame:CGRectMake(0, 0, 0, 0)];
    for (UIView *subview in view.subviews) {
        [subview removeFromSuperview];
    }
}

// ============================================================================
// CONSTRUCTOR CENTRAL (ANTIANUNCIOS ELITE)
// ============================================================================
__attribute__((constructor)) static void initWatusiAntiAdsElite() {
    
    // 1. SWIZZLING DE ALTO NIVEL A NSUSERDEFAULTS (Bypass de almacenamiento local)
    Method origBoolForKey = class_getInstanceMethod([NSUserDefaults class], @selector(boolForKey:));
    if (origBoolForKey) {
        original_boolForKey = (void *)method_getImplementation(origBoolForKey);
        method_setImplementation(origBoolForKey, (IMP)custom_boolForKey);
    }
    
    // 2. DOBLE CAPA SOBRE EL CONTROLADOR PRINCIPAL
    Class watusiManager = NSClassFromString(@"WatusiManager");
    if (watusiManager) {
        NSArray *yesSelectors = @[@"isPurchased", @"adsRemoved", @"isAdFree", @"isPremium", @"purchased"];
        for (NSString *sel in yesSelectors) {
            class_replaceMethod(watusiManager, NSSelectorFromString(sel), (IMP)hook_AlwaysYES, "B@:");
        }
        
        NSArray *noSelectors = @[@"shouldShowAds", @"showAds", @"displayAds", @"bannerEnabled"];
        for (NSString *sel in noSelectors) {
            class_replaceMethod(watusiManager, NSSelectorFromString(sel), (IMP)hook_AlwaysNO, "B@:");
        }
    }
    
    // 3. SECTOR DE CLASES INTERNAS Y DE PROVEEDORES (AdMob, FB, Watusi Nativo)
    NSArray *adClasses = @[
        @"WatusiAdCell", @"WATAdCell", 
        @"WatusiBannerView", @"WATAdBannerRow", 
        @"WatusiMediaAdView", @"WATAdView",
        @"GADBannerView", @"DFPBannerView", 
        @"GADAdLoader", @"BAnationAdView"
    ];
    
    for (NSString *className in adClasses) {
        Class targetClass = NSClassFromString(className);
        if (targetClass) {
            // Forzar tamaños a cero
            class_replaceMethod(targetClass, NSSelectorFromString(@"cellHeight"), (IMP)hook_AlwaysZero, "d@:");
            class_replaceMethod(targetClass, NSSelectorFromString(@"desiredHeight"), (IMP)hook_AlwaysZero, "d@:");
            class_replaceMethod(targetClass, NSSelectorFromString(@"height"), (IMP)hook_AlwaysZero, "d@:");
            
            // Interceptar la inicialización y la carga de peticiones en red de Google AdMob
            class_replaceMethod(targetClass, NSSelectorFromString(@"loadRequest:"), (IMP)hook_BlockAdRequest, "v@:@");
            class_replaceMethod(targetClass, NSSelectorFromString(@"loadAd:"), (IMP)hook_BlockAdRequest, "v@:@");
            
            // Romper el ciclo de dibujado de la interfaz
            class_replaceMethod(targetClass, @selector(layoutSubviews), (IMP)hook_CleanAdView, "v@:");
            class_replaceMethod(targetClass, @selector(didMoveToWindow), (IMP)hook_CleanAdView, "v@:");
        }
    }
}
