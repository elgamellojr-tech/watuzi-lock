#import <UIKit/UIKit.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30
#define URL_IMAGEN_BOTON @"https://i.imgur.com/your_image.png" // CAMBIA ESTA URL POR TU ICONO

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:PREF_KEY];
        
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

        if (fechaActivacion) {
            // --- 1. CONTADOR PERMANENTE ROJO ---
            UIView *counterContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 40, window.bounds.size.width, 30)];
            counterContainer.backgroundColor = [UIColor clearColor];
            counterContainer.userInteractionEnabled = NO;
            
            UILabel *timerLabel = [[UILabel alloc] initWithFrame:counterContainer.bounds];
            timerLabel.textColor = [UIColor redColor];
            timerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
            timerLabel.textAlignment = NSTextAlignmentCenter;
            timerLabel.layer.shadowColor = [UIColor blackColor].CGColor;
            timerLabel.layer.shadowOpacity = 0.8;
            timerLabel.layer.shadowRadius = 2.0;
            timerLabel.layer.shadowOffset = CGSizeMake(1, 1);

            [counterContainer addSubview:timerLabel];
            [window addSubview:counterContainer];

            // --- 2. BOTÓN FLOTANTE PERSONALIZABLE ---
            // Tamaño 50x50 es el estándar que no molesta
            UIButton *floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingButton.frame = CGRectMake(window.bounds.size.width - 70, window.bounds.size.height - 150, 55, 55);
            floatingButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6]; // Fondo semi-transparente
            floatingButton.layer.cornerRadius = 27.5; // Hace el botón circular
            floatingButton.layer.borderWidth = 1.5;
            floatingButton.layer.borderColor = [UIColor redColor].CGColor;
            floatingButton.clipsToBounds = YES;

            // Cargar imagen desde URL de forma sencilla
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL_IMAGEN_BOTON]];
                if (data) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [floatingButton setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
                        floatingButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    });
                }
            });

            // Acción del botón
            [floatingButton addTarget:self action:@selector(handleFloatingButton) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:floatingButton];

            // TIMER DE ACTUALIZACIÓN
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
                if (r <= 0) exit(0);
                
                int d = (int)(r / 86400);
                int h = (int)((NSInteger)r % 86400) / 3600;
                int m = (int)((NSInteger)r % 3600) / 60;
                int s = (int)((NSInteger)r % 60);
                
                timerLabel.text = [NSString stringWithFormat:@"VIP: %02dD %02dH %02dM %02dS", d, h, m, s];
                [window bringSubviewToFront:counterContainer];
                [window bringSubviewToFront:floatingButton];
            }];
        } else {
            // Lógica de activación (Alerta ya configurada anteriormente)
            // ... (Se mantiene igual que el código previo)
        }
    });
}

// Acción al tocar el botón
static void handleFloatingButton() {
    // Aquí puedes poner que abra un menú, Telegram, o lo que desees
    printf("Botón Domidios presionado\n");
}
