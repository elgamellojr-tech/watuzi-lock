#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

// --- CONFIGURACIÓN ESTÉTICA ---
#define COLOR_GOLD [UIColor colorWithRed:0.85 green:0.65 blue:0.13 alpha:1.0]
#define COLOR_BG   [UIColor colorWithWhite:0.05 alpha:0.95]

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    // Esperamos 1.5s para que la app cargue su UI base
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        // Nombre de llave ofuscado para mayor seguridad
        NSString *secureKey = @"sys_auth_token_v1";
        NSDate *fechaActivacion = [prefs objectForKey:secureKey];
        
        // 1. GENERACIÓN DE IDENTIDAD ÚNICA (HWID)
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (!deviceID) return;
        NSString *shortID = [[deviceID substringToIndex:6] uppercaseString];
        
        // Formato de llave maestra
        NSString *keyMaestra = [NSString stringWithFormat:@"VIP-%@-7", shortID];
        
        // 2. OBTENER LA VENTANA PRINCIPAL (SOPORTA iOS 13-18+)
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
        if (fechaActivacion) {
            NSTimeInterval restante = (30 * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];

            if (restante > 0) {
                // BANNER VIP ANIMADO (En lugar de alerta molesta)
                UIView *banner = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width-280)/2, -100, 280, 50)];
                banner.backgroundColor = COLOR_BG;
                banner.layer.cornerRadius = 15;
                banner.layer.borderWidth = 1.5;
                banner.layer.borderColor = COLOR_GOLD.CGColor;
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:banner.bounds];
                lbl.text = [NSString stringWithFormat:@"💎 VIP ACTIVO: %d DÍAS", (int)(restante/86400)];
                lbl.textColor = [UIColor whiteColor];
                lbl.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
                lbl.textAlignment = NSTextAlignmentCenter;
                
                [banner addSubview:lbl];
                [window addSubview:banner];

                // Animación de entrada y salida
                [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
                    banner.transform = CGAffineTransformMakeTranslation(0, 150);
                } completion:^(BOOL f) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.5 animations:^{ banner.alpha = 0; } completion:^(BOOL f2){ [banner removeFromSuperview]; }];
                    });
                }];
                return;
            } else {
                // BLOQUEO POR EXPIRACIÓN
                window.backgroundColor = [UIColor blackColor];
                exit(0);
            }
        }

        // 4. INTERFAZ DE ACTIVACIÓN PROFESIONAL
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ SISTEMA DOMIDIOS"
                                    message:[NSString stringWithFormat:@"Copia tu HWID y solicita tu llave:\n\n🔑 ID: %@", shortID]
                                    preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"VIP-XXXXXX-7";
            tf.keyboardAppearance = UIKeyboardAppearanceDark;
            tf.textAlignment = NSTextAlignmentCenter;
            tf.font = [UIFont fontWithName:@"Courier-Bold" size:16];
        }];

        UIAlertAction *activar = [UIAlertAction actionWithTitle:@"🔓 ACTIVAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *input = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if ([input isEqualToString:keyMaestra]) {
                AudioServicesPlaySystemSound(1519); // Vibración de éxito
                [prefs setObject:[NSDate date] forKey:secureKey];
                [prefs synchronize];
                
                // Reiniciar para aplicar cambios
                exit(0);
            } else {
                AudioServicesPlaySystemSound(1521); // Vibración de error
                exit(0);
            }
        }];

        UIAlertAction *copy = [UIAlertAction actionWithTitle:@"📋 COPIAR ID" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
            [UIPasteboard generalPasteboard].string = shortID;
            exit(0);
        }];

        [alert addAction:copy];
        [alert addAction:activar];
        
        UIViewController *root = window.rootViewController;
        while(root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}
