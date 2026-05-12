#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_logic_init() {
    // Esperamos 3 segundos para que la interfaz de la app cargue
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // 1. Lógica de conteo y expiración
        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            int diasPasados = (int)(segundosTranscurridos / 86400); // 86400 segundos = 1 día
            int diasRestantes = 30 - diasPasados;

            if (diasRestantes <= 0) {
                // SI YA PASARON LOS 30 DÍAS
                UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIAlertController *expired = [UIAlertController alertControllerWithTitle:@"ACCESO EXPIRADO" 
                                             message:@"Tu licencia de 30 días ha terminado.\nContacta a iOS DOMIDIOS para renovar." 
                                             preferredStyle:UIAlertControllerStyleAlert];
                [root presentViewController:expired animated:YES completion:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
                return;
            } else {
                // OPCIONAL: Mostrar un mensaje rápido de cuántos días le quedan (puedes borrar esto si quieres que sea silencioso)
                NSLog(@"[DOMIDIOS] Días restantes: %d", diasRestantes);
            }
        }

        // 2. Interfaz de solicitud de Key (solo si no está activado o no ha expirado)
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"iOS DOMIDIOS"
                                        message:@"Introduce tu Key para activar 30 días de uso"
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Key de acceso";
                textField.secureTextEntry = YES;
            }];

            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"Activar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                // AQUÍ PONES TU CONTRASEÑA
                if ([inputKey isEqualToString:@"WTDFGTHGUER"]) {
                    // GUARDAMOS LA FECHA EXACTA DE AHORA
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"¡Éxito!" 
                                                 message:@"Key activada por 30 días." 
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    [success addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [rootVC presentViewController:success animated:YES completion:nil];
                } else {
                    exit(0); // Clave incorrecta, cierra la app
                }
            }];

            [alert addAction:activar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
