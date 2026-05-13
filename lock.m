#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

// --- CONFIGURACIÓN ---
#define FIRMA_AUTOR @"VIP"
#define SALT_SECRETO @"RPT"
#define DURACION_DIAS 30

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *storageKey = @"internal_token_vip_rpt";
        NSDate *fechaActivacion = [prefs objectForKey:storageKey];
        
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (!deviceID) return;
        NSString *shortID = [[deviceID substringToIndex:6] uppercaseString];
        
        NSString *keyMaestra = [NSString stringWithFormat:@"%@-%@-%@-7", FIRMA_AUTOR, shortID, SALT_SECRETO];
        
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

        // --- CASO: LICENCIA ACTIVA ---
        if (fechaActivacion) {
            NSTimeInterval restante = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            if (restante > 0) {
                UIView *vB = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width-280)/2, -100, 280, 45)];
                vB.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
                vB.layer.cornerRadius = 12;
                vB.layer.borderWidth = 1.0;
                vB.layer.borderColor = [UIColor systemYellowColor].CGColor;
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:vB.bounds];
                lbl.text = [NSString stringWithFormat:@"🌟 %@ ACCESO: %d DÍAS", FIRMA_AUTOR, (int)(restante/86400)];
                lbl.textColor = [UIColor whiteColor];
                lbl.font = [UIFont boldSystemFontOfSize:14];
                lbl.textAlignment = NSTextAlignmentCenter;
                
                [vB addSubview:lbl];
                [window addSubview:vB];
                
                [UIView animateWithDuration:0.7 animations:^{
                    // Cambiado para no usar CoreGraphics directamente
                    vB.center = CGPointMake(window.center.x, 100);
                } completion:^(BOOL f) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.5 animations:^{ vB.alpha=0; } completion:^(BOOL f2){ [vB removeFromSuperview]; }];
                    });
                }];
                return;
            }
        }

        // --- CASO: ACTIVACIÓN ---
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blurView.frame = window.bounds;
        [window addSubview:blurView];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"💎 %@ SYSTEM", FIRMA_AUTOR]
                                    message:[NSString stringWithFormat:@"ID: %@\nEnvíalo para recibir tu llave.", shortID]
                                    preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"VIP-XXXXXX-RPT-7";
            tf.keyboardAppearance = UIKeyboardAppearanceDark;
            tf.textAlignment = NSTextAlignmentCenter;
        }];

        UIAlertAction *btnActivate = [UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            if ([alert.textFields.firstObject.text isEqualToString:keyMaestra]) {
                AudioServicesPlaySystemSound(1519); 
                [prefs setObject:[NSDate date] forKey:storageKey];
                [prefs synchronize];
                [blurView removeFromSuperview];
            } else {
                AudioServicesPlaySystemSound(1521);
                exit(0);
            }
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"📋 COPIAR" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
            [UIPasteboard generalPasteboard].string = shortID;
            exit(0);
        }]];

        [alert addAction:btnActivate];
        
        UIViewController *root = window.rootViewController;
        while(root.presentedViewController) root = root.presentedViewController;
        [root presentViewController:alert animated:YES completion:nil];
    });
}
