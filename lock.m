#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

// --- CONFIGURACIÓN DE SEGURIDAD PERSONALIZADA ---
#define FIRMA_AUTOR @"VIP"             // Tu marca ahora es VIP
#define SALT_SECRETO @"RPT"            // Tu salt secreto
#define DURACION_DIAS 30

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    // Retraso para asegurar que la interfaz esté lista
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *storageKey = @"internal_token_vip_rpt"; // Llave de guardado actualizada
        NSDate *fechaActivacion = [prefs objectForKey:storageKey];
        
        // 1. GENERACIÓN DE IDENTIFICADOR ÚNICO (HWID)
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (!deviceID) return;
        NSString *shortID = [[deviceID substringToIndex:6] uppercaseString];
        
        // 2. ALGORITMO DE LLAVE MAESTRA
        // Formato resultante: VIP-[ID]-RPT-7
        NSString *keyMaestra = [NSString stringWithFormat:@"%@-%@-%@-7", 
                                FIRMA_AUTOR, 
                                shortID, 
                                SALT_SECRETO];
        
        // 3. CAPA VISUAL (WINDOW Y BLUR)
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

        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blurView.frame = window.bounds;
        blurView.alpha = 0;

        // --- VALIDACIÓN DE SUSCRIPCIÓN ACTIVA ---
        if (fechaActivacion) {
            NSTimeInterval transcurrido = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval restante = (DURACION_DIAS * 86400) - transcurrido;

            if (restante > 0) {
                // Banner elegante de bienvenida
                UIView *vB = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width-280)/2, -100, 280, 45)];
                vB.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9];
                vB.layer.cornerRadius = 12;
                vB.layer.borderWidth = 1.0;
                vB.layer.borderColor = [UIColor systemYellowColor].CGColor; // Dorado para VIP
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:vB.bounds];
                lbl.text = [NSString stringWithFormat:@"🌟 %@ ACCESO: %d DÍAS", FIRMA_AUTOR, (int)(restante/86400)];
                lbl.textColor = [UIColor whiteColor];
                lbl.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
                lbl.textAlignment = NSTextAlignmentCenter;
                
                [vB addSubview:lbl];
                [window addSubview:vB];
                [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.6 options:0 animations:^{ vB.transform = CGAffineTransformMakeTranslation(0, 150); } completion:^(BOOL f){
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.5 animations:^{ vB.alpha=0; } completion:^(BOOL f2){ [vB removeFromSuperview]; }];
                    });
                }];
                return;
            }
        }

        // --- MENÚ DE ACTIVACIÓN ---
        [window addSubview:blurView];
        [UIView animateWithDuration:0.4 animations:^{ blurView.alpha = 1.0; }];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"💎 %@ SYSTEM", FIRMA_AUTOR]
                                    message:[NSString stringWithFormat:@"Tu ID de dispositivo es: %@\nEnvíalo para recibir tu llave.", shortID]
                                    preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"VIP-XXXXXX-RPT-7";
            tf.keyboardAppearance = UIKeyboardAppearanceDark;
            tf.textAlignment = NSTextAlignmentCenter;
            tf.textColor = [UIColor systemYellowColor];
        }];

        UIAlertAction *btnActivate = [UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            if ([alert.textFields.firstObject.text isEqualToString:keyMaestra]) {
                AudioServicesPlaySystemSound(1519); 
                [prefs setObject:[NSDate date] forKey:storageKey];
                [prefs synchronize];
                [UIView animateWithDuration:0.5 animations:^{ blurView.alpha = 0; } completion:^(BOOL f){ [blurView removeFromSuperview]; }];
            } else {
                AudioServicesPlaySystemSound(1521);
                exit(0);
            }
        }];

        UIAlertAction *btnCopy = [UIAlertAction actionWithTitle:@"📋 COPIAR ID" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
            [UIPasteboard generalPasteboard].string = shortID;
            exit(0); 
        }];

        [alert addAction:btnCopy];
        [alert addAction:btnActivate];
        
        UIViewController *root = window.rootViewController;
        while(root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}
