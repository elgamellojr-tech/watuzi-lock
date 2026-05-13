#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30

static BOOL isVerifiedActive = NO;

// --- CLASE PARA MANEJAR EL MENÚ ---
@interface DomidiosManager : NSObject
+ (void)handleTap:(UIButton *)sender;
@end

@implementation DomidiosManager

+ (void)handleTap:(UIButton *)sender {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(root.presentedViewController) root = root.presentedViewController;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🚀 PANEL VIP" 
                                message:@"iOS DOMIDIOS" 
                                preferredStyle:UIAlertControllerStyleActionSheet];

    [menu addAction:[UIAlertAction actionWithTitle:@"⚡ Anti atraso" style:UIAlertActionStyleDefault handler:nil]];

    [menu addAction:[UIAlertAction actionWithTitle:isVerifiedActive ? @"🔵 Verificado WA: ON" : @"Verificado WA: OFF" 
                                              style:UIAlertActionStyleDefault 
                                            handler:^(UIAlertAction *action) {
        isVerifiedActive = !isVerifiedActive;
        
        UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"SISTEMA" 
                                     message:isVerifiedActive ? @"Verificación de WhatsApp Activa 🔵" : @"Verificación Desactivada" 
                                     preferredStyle:UIAlertControllerStyleAlert];
        [confirm addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [root presentViewController:confirm animated:YES completion:nil];
    }]];

    [menu addAction:[UIAlertAction actionWithTitle:@"❌ Cerrar" style:UIAlertActionStyleCancel handler:nil]];
    menu.popoverPresentationController.sourceView = sender;
    [root presentViewController:menu animated:YES completion:nil];
}
@end

// --- HOOK ESTILO WHATSAPP VERIFIED ---
@interface UILabel (DomidiosWA)
@end

// --- HOOK ESTILO WHATSAPP VERIFIED (VERSIÓN REAL) ---
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
    // Filtro para que solo aparezca en nombres y no en mensajes largos o vacíos
    if (isVerifiedActive && text.length > 0 && text.length < 35) {
        
        // Color Celeste/Azul oficial de la insignia de WhatsApp
        UIColor *waBlue = [UIColor colorWithRed:0.00 green:0.64 blue:0.85 alpha:1.0];
        
        // Creamos el texto con el nombre original
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", text]];
        
        // Añadimos el Check Mark (\u2714 es el check pesado estilizado)
        NSDictionary *attrs = @{
            NSForegroundColorAttributeName: waBlue,
            NSFontAttributeName: [UIFont systemFontOfSize:self.font.pointSize weight:UIFontWeightBold]
        };
        
        NSAttributedString *badge = [[NSAttributedString alloc] initWithString:@"\u2714" attributes:attrs];
        [attString appendAttributedString:badge];
        
        // Aplicamos el cambio visual
        self.attributedText = attString;
        
        // Llamada técnica para evitar loops (importante para que no se trabe)
        [self domidios_setWAText:text];
    } else {
        // Si el menú está OFF, vuelve al texto normal
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
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (!window && @available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) return;

        if (fecha) {
            // 1. CONTADOR (POSICIÓN ALTA)
            UIView *cView = [[UIView alloc] initWithFrame:CGRectMake(0, 25, window.bounds.size.width, 30)];
            UILabel *timerLabel = [[UILabel alloc] initWithFrame:cView.bounds];
            timerLabel.textColor = [UIColor redColor];
            timerLabel.font = [UIFont boldSystemFontOfSize:13];
            timerLabel.textAlignment = NSTextAlignmentCenter;
            [cView addSubview:timerLabel];
            [window addSubview:cView];

            // 2. BOTÓN VIP (POSICIÓN ALTA)
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(window.bounds.size.width - 60, window.bounds.size.height * 0.20, 55, 55);
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            btn.layer.cornerRadius = 27.5;
            btn.layer.borderWidth = 2.0;
            btn.layer.borderColor = [UIColor redColor].CGColor;
            [btn setTitle:@"VIP" forState:UIControlStateNormal];
            [btn addTarget:[DomidiosManager class] action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:btn];

            // 3. ACTUALIZACIÓN TIEMPO
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
                NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fecha];
                if (r <= 0) exit(0);
                int d = (int)(r / 86400), h = (int)((NSInteger)r % 86400) / 3600, m = (int)((NSInteger)r % 3600) / 60, s = (int)((NSInteger)r % 60);
                timerLabel.text = [NSString stringWithFormat:@"VIP: %02dD %02dH %02dM %02dS", d, h, m, s];
                [window bringSubviewToFront:cView];
                [window bringSubviewToFront:btn];
            }];
        } else {
            // Activación...
            NSString *shortID = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:5] uppercaseString];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ACTIVACIÓN" 
                                        message:[NSString stringWithFormat:@"ID: %@", shortID] 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:nil];
            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                if ([alert.textFields.firstObject.text isEqualToString:[NSString stringWithFormat:@"VIP-%@-7", shortID]]) {
                    [prefs setObject:[NSDate date] forKey:PREF_KEY]; [prefs synchronize]; exit(0);
                } else { exit(0); }
            }]];
            UIViewController *root = window.rootViewController;
            while(root.presentedViewController) root = root.presentedViewController;
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
