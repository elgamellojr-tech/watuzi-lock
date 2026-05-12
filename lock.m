#import <UIKit/UIKit.h>

// Función para mostrar la alerta de bloqueo
void showLockAlert(UIViewController *rootVC) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔐 SISTEMA DOMIDIOS"
                                                                   message:@"Esta versión de Watusi está protegida.\nIntroduce tu Key de acceso:"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Key Personal";
        textField.secureTextEntry = YES;
        textField.keyboardType = UIKeyboardTypeASCIICapable;
    }];

    UIAlertAction *validate = [UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *keyField = alert.textFields.firstObject;
        
        // --- AQUÍ CAMBIA LA CONTRASEÑA ---
        NSString *masterKey = @"iosDOMIDIOS"; 
        // ---------------------------------

        if ([keyField.text isEqualToString:masterKey]) {
            NSLog(@"[DOMIDIOS] Acceso autorizado.");
        } else {
            // Si la clave es incorrecta, vuelve a mostrar la alerta (bucle de bloqueo)
            showLockAlert(rootVC);
        }
    }];

    [alert addAction:validate];
    [rootVC presentViewController:alert animated:YES completion:nil];
}

__attribute__((constructor))
static void initialize() {
    // Espera a que la interfaz de la app esté lista
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window.rootViewController) {
            showLockAlert(window.rootViewController);
        }
    });
}
