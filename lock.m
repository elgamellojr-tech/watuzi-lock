#import <UIKit/UIKit.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30
#define AUTOR_NAME @"iOS DOMIDIOS VIP" 

static void mostrar_contador_vip(UIWindow *window, NSDate *fecha);
static void verificar_y_bloquear(void);

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    // Observador para detectar cuando la app vuelve de segundo plano
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        verificar_y_bloquear();
    }];

    // Ejecución inicial
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        verificar_y_bloquear();
    });
}

static void verificar_y_bloquear() {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDate *fechaActivacion = [prefs objectForKey:PREF_KEY];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window && @available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                window = scene.windows.firstObject; break;
            }
        }
    }
    
    if (!window) return;

    if (fechaActivacion) {
        mostrar_contador_vip(window, fechaActivacion);
    } else {
        // Si ya hay una alerta presentada, no duplicarla, pero si no hay nada, BLOQUEAR
        UIViewController *root = window.rootViewController;
        while(root.presentedViewController) {
            if ([root.presentedViewController isKindOfClass:[UIAlertController class]]) return;
            root = root.presentedViewController;
        }

        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"\n🔐 %@", AUTOR_NAME] 
                                    message:[NSString stringWithFormat:@"iD: %@\n\nPlease enter your license key.", shortID] 
                                    preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"entra tu key aqui";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.secureTextEntry = YES;
            textField.keyboardAppearance = UIKeyboardAppearanceDark;
        }];

        UIAlertAction *authAction = [UIAlertAction actionWithTitle:@"ACEPTAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *input = alert.textFields.firstObject.text;
            // Tu lógica de llave: WRT + ID + 27
            NSString *masterKey = [NSString stringWithFormat:@"WRT%@27", shortID];

            if ([input isEqualToString:masterKey]) {
                NSDate *ahora = [NSDate date];
                [prefs setObject:ahora forKey:PREF_KEY];
                [prefs synchronize];
                
                UIAlertController *success = [UIAlertController alertControllerWithTitle:@"ÉXITO" 
                                             message:@"Autorización completada correctamente." 
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                [window.rootViewController presentViewController:success animated:YES completion:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [success dismissViewControllerAnimated:YES completion:^{
                            mostrar_contador_vip(window, ahora);
                        }];
                    });
                }];
            } else {
                exit(0);
            }
        }];

        [alert addAction:authAction];
        [root presentViewController:alert animated:YES completion:nil];
    }
}

static void mostrar_contador_vip(UIWindow *window, NSDate *fecha) {
    // Evitar duplicar el contador si ya existe
    if ([window viewWithTag:999]) return;

    UIView *cView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, window.bounds.size.width, 30)];
    cView.tag = 999; // Tag para identificarlo
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:cView.bounds];
    timerLabel.textColor = [UIColor redColor];
    timerLabel.font = [UIFont boldSystemFontOfSize:13];
    timerLabel.textAlignment = NSTextAlignmentCenter;
    [cView addSubview:timerLabel];
    [window addSubview:cView];

    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fecha];
        if (r <= 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_KEY];
            exit(0);
        }
        
        int d = (int)(r / 86400), h = (int)((NSInteger)r % 86400) / 3600, m = (int)((NSInteger)r % 3600) / 60, s = (int)((NSInteger)r % 60);
        timerLabel.text = [NSString stringWithFormat:@"%02dD %02dH %02dM %02dS", d, h, m, s];
        [window bringSubviewToFront:cView];
    }];
}
