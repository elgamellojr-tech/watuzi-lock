#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // --- OBTENER ID ÚNICO DEL DISPOSITIVO (IDFV) ---
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        // Extraemos 5 caracteres para mantener la key corta pero segura
        NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
        
        // --- BÚSQUEDA DE VENTANA ACTIVA ---
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

        // --- LÓGICA DE TIEMPO (30 DÍAS) ---
        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval tiempoRestante = (30 * 86400) - segundosTranscurridos;

            if (tiempoRestante <= 0) {
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ LICENCIA VENCIDA" 
                                         message:@"Tu suscripción ha finalizado.\n📲 Renueva con: @iOS_DOMIDIOS" 
                                         preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                return;
            } else {
                int dias = (int)(tiempoRestante / 86400);
                int horas = (int)(((NSInteger)tiempoRestante % 86400) / 3600);
                
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" 
                                             message:[NSString stringWithFormat:@"Acceso activo.\n⏳ Quedan: %d días y %d horas", dias, horas] 
                                             preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
            }
        }

        // --- MENÚ DE ACTIVACIÓN CON NUEVO FORMATO DE KEY ---
        if (!fechaActivacion) {
            NSString *msgMsg = [NSString stringWithFormat:@"Tu ID de registro es: %@\n\nEnvíalo a @iOS_DOMIDIOS para recibir tu llave personalizada.", shortID];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN DOMIDIOS"
                                        message:msgMsg
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"ingresa tu key aqui";
                tf.secureTextEntry = YES;
                tf.keyboardAppearance = UIKeyboardAppearanceDark;
                tf.textAlignment = NSTextAlignmentCenter;
            }];

            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                // --- FORMATO SOLICITADO: VIP-[ID]-7 ---
                NSString *keyMaestra = [NSString stringWithFormat:@"VIP-%@-7", shortID];
                
                if ([inputKey isEqualToString:keyMaestra]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ ACTIVADO" 
                                                 message:@"¡Gracias por tu compra!\nDisfruta de 30 días VIP." 
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    [rootVC presentViewController:success animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [success dismissViewControllerAnimated:YES completion:nil]; });
                } else {
                    // Si la key no es idéntica al formato VIP-ID-7, cierra la app.
                    exit(0);
                }
            }];

            [alert addAction:activar];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
