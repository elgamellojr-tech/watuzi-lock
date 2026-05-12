#import <UIKit/UIKit.h>

// --- GRUPO DE PARCHES VIP (FLEX) ---
%group ParchesVIP
    // Anti-Visto
    %hook WAChatSessionViewController
    - (void)sendReadReceipt { /* Bloqueado */ }
    %end

    // Ghost Status
    %hook WAStatusMessageManager
    - (void)sendReadReceiptForMessage:(id)arg1 { /* Bloqueado */ }
    %end

    // Anti-Revoke (Mensajes eliminados)
    %hook WAMessage
    - (void)setRevoked:(BOOL)arg1 { %orig(NO); }
    %end

    // Ocultar Escribiendo
    %hook WAChatSessionsViewController
    - (void)sendTypingStatus { /* Bloqueado */ }
    %end

    // Duración de estados
    %hook WAStaticConstants
    + (double)maximumStatusVideoDuration { return 9999.0; }
    %end
%end

// --- LÓGICA DE VALIDACIÓN CADA VEZ QUE ABRE ---

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_non_persistent_init() {
    // Espera para que cargue la interfaz
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ iOS DOMIDIOS SECURITY"
                                        message:@"Introduce tu llave para activar los parches VIP.\n(Requerido cada vez que inicies)"
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"Introduce Key";
                tf.secureTextEntry = YES;
                tf.keyboardAppearance = UIKeyboardAppearanceDark;
                tf.textAlignment = NSTextAlignmentCenter;
            }];

            UIAlertAction *validar = [UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                // 1. Verificar si la clave es correcta
                if ([inputKey isEqualToString:@"WTDFGTHGUER"]) {
                    
                    NSDate *firstActivation = [prefs objectForKey:@"fecha_registro_domidios"];
                    
                    if (!firstActivation) {
                        // Es la primera vez que la pone, guardamos hoy como inicio de los 30 días
                        firstActivation = [NSDate date];
                        [prefs setObject:firstActivation forKey:@"fecha_registro_domidios"];
                        [prefs synchronize];
                    }

                    // 2. Verificar si ya pasaron los 30 días desde esa primera vez
                    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:firstActivation];
                    if (elapsed > 2592000) { // 30 días en segundos
                        UIAlertController *expired = [UIAlertController alertControllerWithTitle:@"❌ KEY EXPIRADA" 
                                                     message:@"Tus 30 días han terminado.\nCompra una nueva key con iOS DOMIDIOS." 
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        [rootVC presentViewController:expired animated:YES completion:nil];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                    } else {
                        // 3. TODO OK: Activamos los parches de Flex
                        %init(ParchesVIP);
                        
                        // Pequeña notificación de éxito
                        NSLog(@"[DOMIDIOS] Parches Flex cargados correctamente.");
                    }
                } else {
                    // Clave incorrecta
                    exit(0);
                }
            }];

            [alert addAction:validar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
