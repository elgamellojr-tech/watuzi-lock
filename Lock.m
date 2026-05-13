#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

// --- CONFIGURACIÓN DE IDENTIDAD ---
#define PREF_KEY_DATA  @"internal_db_auth_v2"
#define THEME_COLOR    [UIColor colorWithRed:0.83 green:0.68 blue:0.21 alpha:1.0] // Dorado
#define DURATION_DAYS  30

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *activationDate = [prefs objectForKey:PREF_KEY_DATA];
        
        // 1. GENERACIÓN DE IDENTIDAD
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *shortID = [[deviceID substringToIndex:6] uppercaseString];
        NSString *masterKey = [NSString stringWithFormat:@"VIP-%@-7", shortID];
        
        // 2. OBTENCIÓN DE VENTANA
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        // 3. LÓGICA DE SUSCRIPCIÓN ACTIVA
        if (activationDate) {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:activationDate];
            NSTimeInterval remaining = (DURATION_DAYS * 86400) - elapsed;

            if (remaining > 0) {
                UIView *banner = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width-300)/2, -100, 300, 55)];
                banner.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
                banner.layer.cornerRadius = 18;
                banner.layer.borderWidth = 1.2;
                banner.layer.borderColor = THEME_COLOR.CGColor;
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:banner.bounds];
                lbl.text = [NSString stringWithFormat:@"🌟 VIP STATUS: %d DÍAS RESTANTES", (int)(remaining/86400)];
                lbl.textColor = [UIColor whiteColor];
                lbl.font = [UIFont fontWithName:@"AvenirNext-Bold" size:13];
                lbl.textAlignment = NSTextAlignmentCenter;
                
                [banner addSubview:lbl];
                [window addSubview:banner];

                [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.4 options:0 animations:^{
                    banner.transform = CGAffineTransformMakeTranslation(0, 160);
                } completion:^(BOOL f) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.6 animations:^{ banner.alpha = 0; } completion:^(BOOL f2){ [banner removeFromSuperview]; }];
                    });
                }];
                return;
            } else {
                exit(0);
            }
        }

        // 4. INTERFAZ DE ACTIVACIÓN
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = window.bounds;
        blur.alpha = 0;
        [window addSubview:blur];
        [UIView animateWithDuration:0.4 animations:^{ blur.alpha = 1.0; }];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"💎 DOMIDIOS ELITE"
                                    message:[NSString stringWithFormat:@"Acceso Privado Protegido.\n🔑 HWID: %@", shortID]
                                    preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"Introduce tu llave VIP";
            tf.keyboardAppearance = UIKeyboardAppearanceDark;
            tf.textAlignment = NSTextAlignmentCenter;
            tf.font = [UIFont fontWithName:@"Courier" size:15];
            tf.textColor = THEME_COLOR;
        }];

        UIAlertAction *btnOk = [UIAlertAction actionWithTitle:@"🔓 DESBLOQUEAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            if ([alert.textFields.firstObject.text isEqualToString:masterKey]) {
                AudioServicesPlaySystemSound(1519); 
                [prefs setObject:[NSDate date] forKey:PREF_KEY_DATA];
                [prefs synchronize];
                [UIView animateWithDuration:0.4 animations:^{ blur.alpha = 0; } completion:^(BOOL f){ [blur removeFromSuperview]; }];
            } else {
                AudioServicesPlaySystemSound(1521); 
                exit(0);
            }
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"SALIR" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) { exit(0); }]];
        [alert addAction:btnOk];
        
        UIViewController *root = window.rootViewController;
        while(root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}
