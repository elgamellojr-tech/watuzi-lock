#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // --- BÚSQUEDA DE VENTANA Y CONTROLLER (NECESARIO PARA AMBOS CASOS) ---
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

        // --- LÓGICA DE TIEMPO RESTANTE (DÍAS Y HORAS) ---
        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval totalSuscripcion = 30 * 86400; // 30 días en segundos
            NSTimeInterval tiempoRestante = totalSuscripcion - segundosTranscurridos;

            if (tiempoRestante <= 0) {
                // LICENCIA VENCIDA
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ LICENCIA VENCIDA" 
                                         message:@"Tu suscripción ha finalizado.\n\nRenueva con:\n📲 @iOS_DOMIDIOS" 
                                         preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                return;
            } else {
                // CALCULAR DÍAS Y HORAS RESTANTES
                int dias = (int)(tiempoRestante / 86400);
                int horas = (int)(((NSInteger)tiempoRestante % 86400) / 3600);

                // MOSTRAR STATUS DE LA SUSCRIPCIÓN AL ENTRAR
                NSString *statusMsg = [NSString stringWithFormat:@"Tu acceso vence en:\n⏳ %d días y %d horas", dias, horas];
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" 
                                             message:statusMsg 
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                [rootVC presentViewController:status animated:YES completion:nil];
                
                // Se quita solo después de 3 segundos para no molestar
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [status dismissViewControllerAnimated:YES completion:nil];
                });
            }
        }

        // --- MENÚ DE ACTIVACIÓN (PRIMERA VEZ) ---
        if (!fechaActivacion) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ iOS DOMIDIOS SECURITY"
                                        message:@"Introduce tu llave para activar 30 días VIP."
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Escribe tu Key aquí...";
                textField.secureTextEntry = YES;
                textField.keyboardAppearance = UIKeyboardAppearanceDark;
                textField.textAlignment = NSTextAlignmentCenter;
            }];

            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"VERIFICAR ACCESO" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                if ([inputKey isEqualToString:@"WTDFGTHGUER"]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ ACTIVADO" 
                                                 message:@"¡Acceso concedido!\nTe quedan 30 días exactos." 
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    [rootVC presentViewController:success animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
