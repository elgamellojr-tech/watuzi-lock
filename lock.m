#import <UIKit/UIKit.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30
#define URL_BOTON @"https://i.imgur.com/G4Y5N12.png" // Tu icono

// --- CLASE PARA MANEJAR EL MENÚ ---
@interface DomidiosMenu : NSObject
+ (void)showMenu:(UIView *)parent;
@end

@implementation DomidiosMenu
+ (void)showMenu:(UIView *)parent {
    // Obtenemos el RootViewController para presentar el menú
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(root.presentedViewController) root = root.presentedViewController;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🚀 OPCIONES AVANZADAS" 
                                message:@"Panel de Control VIP" 
                                preferredStyle:UIAlertControllerStyleActionSheet];

    // Opción 1: Telegram
    [menu addAction:[UIAlertAction actionWithTitle:@"📱 Contactar Soporte" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/iOS_DOMIDIOS"] options:@{} completionHandler:nil];
    }]];

    // Opción 2: Info de la Suscripción
    [menu addAction:[UIAlertAction actionWithTitle:@"ℹ️ Info de Licencia" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSDate *fecha = [[NSUserDefaults standardUserDefaults] objectForKey:PREF_KEY];
        UIAlertController *info = [UIAlertController alertControllerWithTitle:@"LICENCIA" 
                                    message:[NSString stringWithFormat:@"Activado el: %@", fecha] 
                                    preferredStyle:UIAlertControllerStyleAlert];
        [info addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [root presentViewController:info animated:YES completion:nil];
    }]];

    // Opción 3: Cerrar Menú
    [menu addAction:[UIAlertAction actionWithTitle:@"❌ Cerrar" style:UIAlertActionStyleCancel handler:nil]];

    // Soporte para iPad
    menu.popoverPresentationController.sourceView = parent;
    
    [root presentViewController:menu animated:YES completion:nil];
}
@end

__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
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
            // 1. CONTADOR PERMANENTE ROJO
            UIView *cView = [[UIView alloc] initWithFrame:CGRectMake(0, 45, window.bounds.size.width, 30)];
            UILabel *timerLabel = [[UILabel alloc] initWithFrame:cView.bounds];
            timerLabel.textColor = [UIColor redColor];
            timerLabel.font = [UIFont boldSystemFontOfSize:13];
            timerLabel.textAlignment = NSTextAlignmentCenter;
            [cView addSubview:timerLabel];
            [window addSubview:cView];

            // 2. BOTÓN FLOTANTE (MENÚ)
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(window.bounds.size.width - 60, window.bounds.size.height / 2, 50, 50);
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            btn.layer.cornerRadius = 25;
            btn.layer.borderWidth = 1.0;
            btn.layer.borderColor = [UIColor redColor].CGColor;
            btn.clipsToBounds = YES;

            // Cargar Imagen
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:URL_BOTON]];
                if (data) dispatch_async(dispatch_get_main_queue(), ^{
                    [btn setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
                });
            });

            // Acción del Menú (Usando la clase estática)
            [btn addTarget:[DomidiosMenu class] action:@selector(showMenu:) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:btn];

            // 3. ACTUALIZACIÓN CADA SEGUNDO
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
                NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
                if (r <= 0) exit(0);
                
                int d = (int)(r / 86400);
                int h = (int)((NSInteger)r % 86400) / 3600;
                int m = (int)((NSInteger)r % 3600) / 60;
                int s = (int)((NSInteger)r % 60);
                
                timerLabel.text = [NSString stringWithFormat:@"VIP: %02dD %02dH %02dM %02dS", d, h, m, s];
                [window bringSubviewToFront:cView];
                [window bringSubviewToFront:btn];
            }];
        } else {
            // Lógica de Activación (ID y Alerta)
            NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ACTIVACIÓN" 
                                        message:[NSString stringWithFormat:@"ID: %@", shortID] 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:nil];
            [alert addAction:[UIAlertAction actionWithTitle:@"VERIFICAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                if ([alert.textFields.firstObject.text isEqualToString:[NSString stringWithFormat:@"VIP-%@-7", shortID]]) {
                    [prefs setObject:[NSDate date] forKey:PREF_KEY];
                    [prefs synchronize];
                    exit(0);
                } else { exit(0); }
            }]];
            UIViewController *root = window.rootViewController;
            while(root.presentedViewController) root = root.presentedViewController;
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
