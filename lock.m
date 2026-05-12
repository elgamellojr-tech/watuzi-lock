#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- FUNCIÓN PARA EL GHOST MODE Y ANTI-REVOKE (Sin necesidad de Headers) ---
// Usamos "MSHookMessageEx" o hooks dinámicos para mayor compatibilidad

static void aplicarParchesFlex() {
    // Aquí puedes añadir logs para saber que se activó
    NSLog(@"[DOMIDIOS] Aplicando parches VIP...");

    // Nota: Si usas Theos en GitHub, asegúrate de que el archivo sea Tweak.x
}

%group ParchesVIP
    %hook WAMessage
    - (void)setRevoked:(BOOL)arg1 { %orig(NO); }
    %end

    %hook WAChatSessionViewController
    - (void)sendReadReceipt { /* Bloqueado */ }
    - (void)sendTypingStatus { /* Bloqueado */ }
    %end

    %hook WAStatusMessageManager
    - (void)sendReadReceiptForMessage:(id)arg1 { /* Bloqueado */ }
    %end

    %hook WAStaticConstants
    + (double)maximumStatusVideoDuration { return 9999.0; }
    %end
%end

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_fix_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (!window && @available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        }

        UIViewController *rootVC = window.rootViewController;
        while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;

        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ iOS DOMIDIOS"
                                        message:@"Introduce tu llave para activar parches VIP.\n(Requerido cada inicio)"
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"Key: WTDFGTHGUER";
                tf.secureTextEntry = YES;
                tf.keyboardAppearance = UIKeyboardAppearanceDark;
                tf.textAlignment = NSTextAlignmentCenter;
            }];

            [alert addAction:[UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                if ([inputKey isEqualToString:@"WTDFGTHGUER"]) {
                    NSDate *firstActivation = [prefs objectForKey:@"fecha_registro_domidios"];
                    
                    if (!firstActivation) {
                        firstActivation = [NSDate date];
                        [prefs setObject:firstActivation forKey:@"fecha_registro_domidios"];
                        [prefs synchronize];
                    }

                    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:firstActivation];
                    if (elapsed > 2592000) { 
                        UIAlertController *expired = [UIAlertController alertControllerWithTitle:@"❌ EXPIRADO" message:@"Licencia vencida." preferredStyle:UIAlertControllerStyleAlert];
                        [rootVC presentViewController:expired animated:YES completion:nil];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                    } else {
                        // AQUÍ SE ACTIVAN LOS HOOKS
                        %init(ParchesVIP);
                    }
                } else {
                    exit(0);
                }
            }]];

            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
