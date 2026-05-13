#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // --- LÓGICA DE TIEMPO ---
        if (fechaActivacion) {
            NSTimeInterval segundos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            int diasPasados = (int)(segundos / 86400);
            int diasRestantes = 30 - diasPasados;

            if (diasRestantes <= 0) {
                UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ LICENCIA VENCIDA" 
                                         message:@"Tu periodo de 30 días ha finalizado.\n\nPara renovar el acceso, contacta con:\n📲 @iOS_DOMIDIOS" 
                                         preferredStyle:UIAlertControllerStyleAlert];
                [root presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                return;
            }
        }

        // --- DISEÑO DE LA INTERFAZ ---
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

        if (rootVC && !fechaActivacion) {
            // Título con emojis y nombre de tu marca
            NSString *titulo = @"🛡️ iOS DOMIDIOS SECURITY";
            NSString *mensaje = @"Bienvenido al sistema privado.\nIntroduce tu llave de activación para iniciar tu suscripción de 1 mes.";
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:titulo
                                        message:mensaje
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Escribe tu Key aquí...";
                textField.secureTextEntry = YES;
                textField.keyboardAppearance = UIKeyboardAppearanceDark; // Teclado oscuro
                textField.textAlignment = NSTextAlignmentCenter;
            }];

            // Botón de activación con estilo
            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"VERIFICAR ACCESO" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                if ([inputKey isEqualToString:@"WTDFGTHGUER"]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    // Alerta de éxito elegante
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ ACTIVADO" 
                                                 message:@"Acceso concedido por 30 días.\n¡Disfruta la App!" 
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    [rootVC presentViewController:success animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [success dismissViewControllerAnimated:YES completion:nil];
                    });
                } else {
                    exit(0);
                }
            }];

            [alert addAction:activar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
