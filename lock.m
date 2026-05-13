#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // --- OBTENER ID ÚNICO DEL DISPOSITIVO (Primeras 5 letras del IDFV) ---
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *deviceShortID = [[deviceID substringToIndex:5] uppercaseString];
        
        // --- BÚSQUEDA DE VENTANA Y CONTROLLER ---
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
        if (!rootVC) return;

        // --- LÓGICA DE TIEMPO Y EXPIRACIÓN ---
        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval totalSuscripcion = 30 * 86400; 
            NSTimeInterval tiempoRestante = totalSuscripcion - segundosTranscurridos;

            if (tiempoRestante <= 0) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ LICENCIA VENCIDA" 
                                         message:@"Tu suscripción ha finalizado.\nCompra una nueva llave personal." 
                                         preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                return;
            } else {
                int dias = (int)(tiempoRestante / 86400);
                int horas = (int)(((NSInteger)tiempoRestante % 86400) / 3600);
                NSString *statusMsg = [NSString stringWithFormat:@"ID: %@\n⏳ Vence en: %d días y %d horas", deviceShortID, dias, horas];
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" message:statusMsg preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
            }
        }

        // --- MENÚ DE ACTIVACIÓN CON VINCULACIÓN POR ID ---
        if (![prefs objectForKey:@"fecha_registro_domidios"]) {
            NSString *msgInfo = [NSString stringWithFormat:@"Tu ID es: %@\nProporciona este ID para recibir tu llave.", deviceShortID];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN ÚNICA"
                                        message:msgInfo
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Introduce tu Key personal...";
                textField.secureTextEntry = YES;
                textField.textAlignment = NSTextAlignmentCenter;
            }];

            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"ACTIVAR MI DISPOSITIVO" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                // --- REGLA DE SEGURIDAD ANTISHARE ---
                // La llave debe empezar con VIP, terminar con 7 Y contener el ID corto del dispositivo
                if ([inputKey hasPrefix:@"VIP"] && 
                    [inputKey hasSuffix:@"7"] && 
                    [inputKey containsString:deviceShortID]) {
                    
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ ACTIVADO" message:@"Esta llave ha sido vinculada a este iPhone con éxito." preferredStyle:UIAlertControllerStyleAlert];
                    [rootVC presentViewController:success animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [success dismissViewControllerAnimated:YES completion:nil]; });
                } else {
                    exit(0); // Llave no válida para este dispositivo
                }
            }];

            [alert addAction:activar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
