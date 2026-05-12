#import <UIKit/UIKit.h>

// Esto obliga a que la función se ejecute apenas la App cargue la dylib
__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_lock_init() {
    
    // Esperamos 3 segundos para que WhatsApp cargue su interfaz completa
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Buscamos la ventana principal de la aplicación
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
        
        // Si hay una pantalla encima (como la de Watusi), nos ponemos sobre ella
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }

        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"iOS DOMIDIOS"
                                        message:@"iosDOMIDIOS"
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Contraseña";
                textField.secureTextEntry = YES;
            }];

            UIAlertAction *entrar = [UIAlertAction actionWithTitle:@"Entrar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *pass = alert.textFields.firstObject.text;
                
                // CAMBIA "1234" POR TU CONTRASEÑA REAL
                if ([pass isEqualToString:@"iosDOMIDIOS"]) {
                    NSLog(@"Acceso concedido");
                } else {
                    exit(0); // Cierra la app si falla
                }
            }];

            [alert addAction:entrar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
