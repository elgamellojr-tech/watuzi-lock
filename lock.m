#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// SIMULACIÓN DE COMPRA / REMOCIÓN DE ANUNCIOS (BYPASS LÓGICO)
// ============================================================================
BOOL hook_WatusiNoAds(id self, SEL _cmd) { 
    return YES; // Retorna verdadero a cualquier método tipo "isAdFree" o "hideAds"
}

BOOL hook_WatusiPurchasedStatus(id self, SEL _cmd) { 
    return YES; // Fuerza el estado de cuenta comprada
}

BOOL hook_WatusiShouldNotShowAds(id self, SEL _cmd) {
    return NO; // Fuerza a que "shouldShowAds" devuelva siempre Falso
}

// ============================================================================
// COMPORTAMIENTO DE CELDAS DE ANUNCIOS (FORZAR ALTURA CERO)
// ============================================================================
CGFloat hook_AdCellHeight(id self, SEL _cmd) {
    return 0.0; // Desaparece físicamente el espacio del anuncio en la lista
}

void hook_AdCellLayout(id self, SEL _cmd) {
    // Vacía el layout para que no intente renderizar imágenes ni textos promocionales
    UIView *cell = (UIView *)self;
    cell.hidden = YES;
    for (UIView *subview in cell.subviews) {
        [subview removeFromSuperview];
    }
}

// ============================================================================
// CONSTRUCTOR CENTRAL (INYECTOR ANTIANUNCIOS)
// ============================================================================
__attribute__((constructor)) static void initAntiAdsWatusi() {
    
    // 1. Desactivación mediante el gestor principal de Watusi
    Class watusiManager = NSClassFromString(@"WatusiManager");
    if (watusiManager) {
        // Hooks para forzar el estado Premium/Sin Anuncios
        class_replaceMethod(watusiManager, NSSelectorFromString(@"isPurchased"), (IMP)hook_WatusiPurchasedStatus, "B@:");
        class_replaceMethod(watusiManager, NSSelectorFromString(@"adsRemoved"), (IMP)hook_WatusiNoAds, "B@:");
        class_replaceMethod(watusiManager, NSSelectorFromString(@"shouldShowAds"), (IMP)hook_WatusiShouldNotShowAds, "B@:");
    }
    
    // 2. Bloqueo de Controladores de Anuncios Comunes (AdMob / Custom Banners)
    NSArray *adClasses = @[
        @"WatusiAdCell",
        @"WATAdCell",
        @"WatusiBannerView",
        @"WATAdBannerRow",
        @"WatusiMediaAdView"
    ];
    
    for (NSString *className in adClasses) {
        Class targetAdClass = NSClassFromString(className);
        if (targetAdClass) {
            // Forzamos a que la altura de estas celdas/vistas de publicidad sea 0
            class_replaceMethod(targetAdClass, NSSelectorFromString(@"cellHeight"), (IMP)hook_AdCellHeight, "d@:");
            class_replaceMethod(targetAdClass, NSSelectorFromString(@"desiredHeight"), (IMP)hook_AdCellHeight, "d@:");
            
            // Ocultamos y removemos cualquier subvista interna que intente cargar
            class_replaceMethod(targetAdClass, @selector(layoutSubviews), (IMP)hook_AdCellLayout, "v@:");
        }
    }
}
