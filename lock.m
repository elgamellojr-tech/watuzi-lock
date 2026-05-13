#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    // Retraso de 2.5 segundos para esperar a que la app cargue su interfaz principal
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // --- GENERACIÓN DE IDENTIFICADOR ÚNICO DE DISPOSITIVO ---
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        if (!deviceID) return; // Protegemos en caso de entornos emulados extraños
        
        NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
        NSString *keyMaestra = [NSString stringWithFormat:@"VIP-%@-7", shortID];
        
        // --- LOCALIZACIÓN DE LA VENTANA ACTIVA DEL JUEGO/APP ---
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        // ==========================================
        // CASO 1: LA LICENCIA YA ESTÁ EXPIRADA
        // ==========================================
        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval tiempoRestante = (30 * 86400) - segundosTranscurridos;

            if (tiempoRestante <= 0) {
                // Contenedor de pantalla completa para bloqueo total
                UIView *lockOverlay = [[UIView alloc] initWithFrame:window.bounds];
                lockOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.95];
                
                UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, window.bounds.size.height/2 - 80, window.bounds.size.width - 40, 40)];
                titleLabel.text = @"⚠️ LICENCIA VENCIDA";
                titleLabel.textColor = [UIColor systemRedColor];
                titleLabel.font = [UIFont boldSystemFontOfSize:24];
                titleLabel.textAlignment = NSTextAlignmentCenter;
                
                UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, window.bounds.size.height/2 - 30, window.bounds.size.width - 40, 80)];
                msgLabel.text = @"Tu suscripción VIP de 30 días ha finalizado.\n\nPara renovar tu acceso contacta a:\n📢 @iOS_DOMIDIOS";
                msgLabel.textColor = [UIColor whiteColor];
                msgLabel.numberOfLines = 0;
                msgLabel.font = [UIFont systemFontOfSize:16];
                msgLabel.textAlignment = NSTextAlignmentCenter;
                
                [lockOverlay addSubview:titleLabel];
                [lockOverlay addSubview:msgLabel];
                [window addSubview:lockOverlay];
                
                // Forzar el cierre de la app en 6 segundos de manera elegante
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    exit(0);
                });
                return;
            } else {
                // --- BANNER DE BIENVENIDA VIP COMPACTO Y ELEGANTE ---
                int dias = (int)(tiempoRestante / 86400);
                
                UIView *vipBanner = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width - 280)/2, -100, 280, 55)];
                vipBanner.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:0.95];
                vipBanner.layer.cornerRadius = 15;
                vipBanner.layer.borderWidth = 1.5;
                vipBanner.layer.borderColor = [UIColor colorWithRed:0.85 green:0.65 blue:0.13 alpha:1.0].CGColor; // Dorado Premium
                vipBanner.clipsToBounds = YES;
                
                UILabel *lbl = [[UILabel alloc] initWithFrame:vipBanner.bounds];
                lbl.text = [NSString stringWithFormat:@"🛡️ DOMIDIOS VIP: ACCESO ACTIVO\n⏳ Quedan %d días de suscripción", dias];
                lbl.textColor = [UIColor whiteColor];
                lbl.numberOfLines = 2;
                lbl.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
                lbl.textAlignment = NSTextAlignmentCenter;
                
                [vipBanner addSubview:lbl];
                [window addSubview:vipBanner];
                
                // Animación de entrada y salida (Drop-down premium)
                [UIView animateWithDuration:0.5 animations:^{
                    CGRect frame = vipBanner.frame;
                    frame.origin.y = 50; // Baja a la pantalla
                    vipBanner.frame = frame;
                } completion:^(BOOL finished) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.5 animations:^{
                            CGRect frame = vipBanner.frame;
                            frame.origin.y = -100; // Sube y se oculta
                            vipBanner.frame = frame;
                        } completion:^(BOOL fin) {
                            [vipBanner removeFromSuperview];
                        }];
                    });
                }];
            }
        }

        // ==========================================
        // CASO 2: MENÚ DE ACTIVACIÓN CON LLAVE
        // ==========================================
        if (!fechaActivacion) {
            // UI Alert con estilo Dark Mode refinado
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ SISTEMA DE SEGURIDAD"
                                        message:[NSString stringWithFormat:@"Copia tu HWID y solicita tu llave de activación:\n\n🔑 ID: %@\n\nContacto Oficial: @iOS_DOMIDIOS", shortID]
                                        preferredStyle:UIAlertControllerStyleAlert];

            // Campo de texto personalizado
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"Coloca tu clave VIP aquí";
                tf.secureTextEntry = NO; // Cambiado a NO para que el usuario verifique lo que escribe
                tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                tf.keyboardAppearance = UIKeyboardAppearanceDark;
                tf.textAlignment = NSTextAlignmentCenter;
                tf.font = [UIFont fontWithName:@"Courier-Bold" size:16]; // Fuente tipo serial
            }];

            // Acción para copiar el ID automáticamente y ahorrarle trabajo al cliente
            UIAlertAction *copiarID = [UIAlertAction actionWithTitle:@"📋 COPIAR ID" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [UIPasteboard generalPasteboard].string = shortID;
                
                // Reabrir inmediatamente para que no se escape del menú de activación al copiar
                domidios_premium_init();
            }];

            UIAlertAction *activar = [UIAlertAction actionWithTitle:@"🔓 ACTIVAR ACCESO" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *inputKey = alert.textFields.firstObject.text;
                
                // Limpiar espacios en blanco innecesarios que el usuario pueda meter por error
                inputKey = [inputKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                if ([inputKey isEqualToString:keyMaestra]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    
                    // Alerta de Éxito Limpia
                    UIAlertController *success = [UIAlertController alertControllerWithTitle:@"✅ VERIFICADO" 
                                                 message:@"¡Licencia Premium Activada!\nDisfruta de tus 30 días VIP." 
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIViewController *rootVC = window.rootViewController;
                    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
                    [rootVC presentViewController:success animated:YES completion:nil];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ 
                        [success dismissViewControllerAnimated:YES completion:nil]; 
                    });
                } else {
                    // Animación de parpadeo rojo si la clave es incorrecta antes de cerrar la app
                    window.backgroundColor = [UIColor redColor];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        exit(0);
                    });
                }
            }];

            [alert addAction:copiarID];
            [alert addAction:activar];
            
            UIViewController *rootVC = window.rootViewController;
            while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
