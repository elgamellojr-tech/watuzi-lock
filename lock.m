#import <UIKit/UIKit.h>

// --- SISTEMA DE LICENCIA DOMIDIOS ---
__attribute__((constructor))
static void domidios_licencia_init() {
    // Esperamos 5 segundos para asegurar que la app haya cargado su interfaz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaRegistro = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // Obtener la ventana principal y el RootViewController de forma segura
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        UIViewController *root = window.rootViewController;
        while (root && root.presentedViewController) root = root.presentedViewController;
        if (!root) return;

        // Generar ID único basado en el dispositivo (Primeros 5 caracteres)
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *shortID = [[[[deviceID stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:5] uppercaseString] stringByAppendingString:@""];

        if (fechaRegistro) {
            // Lógica de tiempo restante (30 días de duración)
            NSTimeInterval duracionTotal = 30 * 86400; 
            NSTimeInterval transcurrido = [[NSDate date] timeIntervalSinceDate:fechaRegistro];
            NSTimeInterval restante = duracionTotal - transcurrido;

            if (restante <= 0) {
                // LICENCIA EXPIRADA
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ EXPIRADO" 
                                            message:@"Tu suscripción VIP ha terminado." 
                                            preferredStyle:1];
                [root presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
            } else {
                // LICENCIA ACTIVA - Mostrar Status
                int d = (int)(restante / 86400);
                int h = (int)(((long)restante % 86400) / 3600);
                
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" 
                                            message:[NSString stringWithFormat:@"ID: %@\n⏳ Tiempo restante: %d días y %d horas", shortID, d, h] 
                                            preferredStyle:1];
                
                [root presentViewController:status animated:YES completion:nil];
                
                // Cerrar el aviso de status automáticamente tras 4 segundos
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [status dismissViewControllerAnimated:YES completion:nil];
                });
            }
        } else {
            // NO HAY LICENCIA - Pedir Activación
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN VIP" 
                                        message:[NSString stringWithFormat:@"Envía este ID al administrador:\n\nID: %@", shortID] 
                                        preferredStyle:1];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"Introduce tu Key VIP aquí...";
                tf.secureTextEntry = YES;
                tf.textAlignment = NSTextAlignmentCenter;
            }];
            
            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"ACTIVAR" style:0 handler:^(UIAlertAction *a) {
                NSString *keyUser = alert.textFields.firstObject.text;
                
                // REGLAS DE LA KEY:
                // 1. Debe empezar con VIP
                // 2. Debe terminar con 7
                // 3. Debe contener el ID del dispositivo
                if ([keyUser hasPrefix:@"VIP"] && [keyUser hasSuffix:@"7"] && [keyUser containsString:shortID]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ ÉXITO" message:@"¡Licencia Activada! Reinicia la app." preferredStyle:1];
                    [root presentViewController:success animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                } else {
                    // Key Incorrecta -> Cerrar App
                    exit(0);
                }
            }];
            
            [alert addAction:activar];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
