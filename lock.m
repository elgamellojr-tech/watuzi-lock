#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30

static BOOL isVerifiedActive = NO;

// --- MEJORA DE INTERFAZ Y MANEJO DE MENÚ ---
@interface DomidiosManager : NSObject
+ (void)handleTap:(UIButton *)sender;
@end

@implementation DomidiosManager

+ (void)handleTap:(UIButton *)sender {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(root.presentedViewController) root = root.presentedViewController;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"\n🚀 PANEL VIP" 
                                message:@"iOS DOMIDIOS CUSTOMS" 
                                preferredStyle:UIAlertControllerStyleActionSheet];

    // Acción: Anti-Atraso
    [menu addAction:[UIAlertAction actionWithTitle:@"⚡ Anti atraso" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Lógica de anti-atraso aquí
    }]];

    // Acción: Verificado (Con switch visual en el título)
    NSString *vTitle = isVerifiedActive ? @"🔵 Verificado WA: [ON]" : @"⚪ Verificado WA: [OFF]";
    [menu addAction:[UIAlertAction actionWithTitle:vTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isVerifiedActive = !isVerifiedActive;
        
        // Alerta de confirmación rápida
        UIAlertController *confirm = [UIAlertController alertControllerWithTitle:nil 
                                     message:isVerifiedActive ? @"Insignia Activada" : @"Insignia Desactivada" 
                                     preferredStyle:UIAlertControllerStyleAlert];
        [root presentViewController:confirm animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [confirm dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    }]];

    [menu addAction:[UIAlertAction actionWithTitle:@"❌ Cerrar Panel" style:UIAlertActionStyleCancel handler:nil]];

    // --- FIX PARA IPAD Y PRESENTACIÓN SEGURA ---
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        menu.popoverPresentationController.sourceView = sender;
        menu.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [root presentViewController:menu animated:YES completion:nil];
}
@end

// --- HOOK ESTILO WHATSAPP VERIFIED ---
@interface UILabel (DomidiosWA)
@end

@implementation UILabel (DomidiosWA)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod([self class], @selector(setText:));
        Method swizzled = class_getInstanceMethod([self class], @selector(domidios_setWAText:));
        method_exchangeImplementations(original, swizzled);
    });
}

- (void)domidios_setWAText:(NSString *)text {
    if (isVerifiedActive && text.length > 0 && text.length < 25 && ![text containsString:@"\u2705"]) {
        // Usamos el check azul (Unicode) que mejor se adapta visualmente
        NSString *waVerified = [NSString stringWithFormat:@"%@ \u2705", text]; 
        [self domidios_setWAText:waVerified];
    } else {
        [self domidios_setWAText:text];
    }
}
@end

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fecha = [prefs objectForKey:PREF_KEY];
        UIWindow *window = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!window) return;

        if (fecha) {
            // --- 1. CONTADOR ESTILIZADO (CÁPSULA) ---
            UIView *cView = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width/2)-60, 45, 120, 22)];
            cView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            cView.layer.cornerRadius = 11;
            cView.clipsToBounds = YES;
            
            UILabel *timerLabel = [[UILabel alloc] initWithFrame:cView.bounds];
            timerLabel.textColor = [UIColor whiteColor];
            timerLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
            timerLabel.textAlignment = NSTextAlignmentCenter;
            [cView addSubview:timerLabel];
            [window addSubview:cView];

            // --- 2. BOTÓN VIP MEJORADO (DISEÑO PREMIUM) ---
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(window.bounds.size.width - 65, window.bounds.size.height * 0.40, 55, 55);
            btn.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9];
            btn.layer.cornerRadius = 27.5;
            btn.layer.borderWidth = 1.5;
            btn.layer.borderColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.8].CGColor;
            
            // Sombra para el botón
            btn.layer.shadowColor = [UIColor redColor].CGColor;
            btn.layer.shadowOffset = CGSizeMake(0, 0);
            btn.layer.shadowRadius = 8.0;
            btn.layer.shadowOpacity = 0.5;

            [btn setTitle:@"VIP" forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBlack];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [btn addTarget:[DomidiosManager class] action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:btn];

            // 3. ACTUALIZACIÓN TIEMPO
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
                NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fecha];
                if (r <= 0) exit(0);
                int d = (int)(r / 86400), h = (int)((NSInteger)r % 86400) / 3600, m = (int)((NSInteger)r % 3600) / 60, s = (int)((NSInteger)r % 60);
                timerLabel.text = [NSString stringWithFormat:@"%02dD %02dH %02dM", d, h, m];
                [window bringSubviewToFront:cView];
                [window bringSubviewToFront:btn];
            }];
        } else {
            // (Módulo de activación se mantiene igual por seguridad de tu llave)
            // ... resto del código de activación ...
        }
    });
}
