#import <UIKit/UIKit.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:PREF_KEY];
        
        // ID para la activación
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject; break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        // --- LÓGICA DE CONTADOR PERMANENTE ---
        if (fechaActivacion) {
            NSTimeInterval transcurrido = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval restante = (DURACION_DIAS * 86400) - transcurrido;

            if (restante <= 0) {
                exit(0); 
            } else {
                // CONTENEDOR TRANSPARENTE
                // Lo situamos en la parte superior (ajusta el 'y' si choca con el notch)
                UIView *counterContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 45, window.bounds.size.width, 30)];
                counterContainer.backgroundColor = [UIColor clearColor]; // Fondo transparente
                counterContainer.userInteractionEnabled = NO; // Para que no bloquee toques en la app
                
                UILabel *timerLabel = [[UILabel alloc] initWithFrame:counterContainer.bounds];
                timerLabel.textColor = [UIColor redColor]; // Números en rojo
                timerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
                timerLabel.textAlignment = NSTextAlignmentCenter;
                
                // Sombra para que se lea bien en cualquier fondo
                timerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
                timerLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
                timerLabel.layer.shadowOpacity = 1.0;
                timerLabel.layer.shadowRadius = 1.0;

                [counterContainer addSubview:timerLabel];
                [window addSubview:counterContainer];

                // Timer que actualiza cada segundo y NO se detiene
                [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
                    
                    if (r <= 0) { exit(0); }
                    
                    int d = (int)(r / 86400);
                    int h = (int)((NSInteger)r % 86400) / 3600;
                    int m = (int)((NSInteger)r % 3600) / 60;
                    int s = (int)((NSInteger)r % 60);
                    
                    timerLabel.text = [NSString stringWithFormat:@"VIP: %02dD %02dH %02dM %02dS", d, h, m, s];
                    
                    // Asegurar que el contador siempre esté al frente si la app cambia de vista
                    [window bringSubviewToFront:counterContainer];
                }];
                return;
            }
        }

        // --- MENÚ DE ACTIVACIÓN (SOLO SI NO ESTÁ ACTIVADO) ---
        if (!fechaActivacion) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN"
                                        message:[NSString stringWithFormat:@"ID: %@\nEnvíalo para tu llave.", shortID]
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"VIP-XXXXX-7";
                tf.textAlignment = NSTextAlignmentCenter;
                tf.keyboardAppearance = UIKeyboardAppearanceDark;
            }];

            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *keyMaestra = [NSString stringWithFormat:@"VIP-%@-7", shortID];
                if ([alert.textFields.firstObject.text isEqualToString:keyMaestra]) {
                    [prefs setObject:[NSDate date] forKey:PREF_KEY];
                    [prefs synchronize];
                    exit(0);
                } else {
                    exit(0);
                }
            }]];
            
            UIViewController *root = window.rootViewController;
            while(root.presentedViewController) root = root.presentedViewController;
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
