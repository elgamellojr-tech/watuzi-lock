#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:PREF_KEY];
        
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

        // --- LÓGICA DE CONTADOR SI ESTÁ ACTIVADO ---
        if (fechaActivacion) {
            NSTimeInterval transcurrido = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval restante = (DURACION_DIAS * 86400) - transcurrido;

            if (restante <= 0) {
                exit(0); // O mostrar alerta de expirado
            } else {
                // CREAR BANNER DEL CONTADOR
                UIView *counterView = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width-250)/2, 50, 250, 40)];
                counterView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
                counterView.layer.cornerRadius = 12;
                counterView.layer.borderWidth = 1.0;
                counterView.layer.borderColor = [UIColor systemYellowColor].CGColor;
                
                UILabel *timerLabel = [[UILabel alloc] initWithFrame:counterView.bounds];
                timerLabel.textColor = [UIColor whiteColor];
                timerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
                timerLabel.textAlignment = NSTextAlignmentCenter;
                [counterView addSubview:timerLabel];
                [window addSubview:counterView];

                // Función para actualizar el tiempo cada segundo
                [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
                    if (r <= 0) { exit(0); }
                    
                    int d = (int)(r / 86400);
                    int h = (int)((NSInteger)r % 86400) / 3600;
                    int m = (int)((NSInteger)r % 3600) / 60;
                    int s = (int)((NSInteger)r % 60);
                    
                    timerLabel.text = [NSString stringWithFormat:@"⏳ %02dD %02dH %02dM %02dS", d, h, m, s];
                }];

                // Animación para que el contador desaparezca después de 10 segundos (opcional)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:1.0 animations:^{ counterView.alpha = 0; } completion:^(BOOL f){ [counterView removeFromSuperview]; }];
                });
                return;
            }
        }

        // --- MENÚ DE ACTIVACIÓN (Si no hay fecha) ---
        if (!fechaActivacion) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN"
                                        message:[NSString stringWithFormat:@"ID: %@\nEnvíalo a @iOS_DOMIDIOS", shortID]
                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                tf.placeholder = @"VIP-XXXXX-7";
                tf.textAlignment = NSTextAlignmentCenter;
            }];

            [alert addAction:[UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSString *keyMaestra = [NSString stringWithFormat:@"VIP-%@-7", shortID];
                if ([alert.textFields.firstObject.text isEqualToString:keyMaestra]) {
                    [prefs setObject:[NSDate date] forKey:PREF_KEY];
                    [prefs synchronize];
                    exit(0); // Reiniciar para activar contador
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
