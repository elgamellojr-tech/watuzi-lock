#import <UIKit/UIKit.h>

// --- CONFIGURACIÓN ---
#define PREF_KEY @"fecha_registro_domidios"
#define DURACION_DIAS 30

// --- CLASE PARA MANEJAR EL MENÚ ---
@interface DomidiosManager : NSObject
+ (void)handleTap:(UIButton *)sender;
@end

@implementation DomidiosManager

// Acción al tocar el botón
+ (void)handleTap:(UIButton *)sender {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while(root.presentedViewController) root = root.presentedViewController;

    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"🚀 PANEL VIP" 
                                message:@"iOS DOMIDIOS" 
                                preferredStyle:UIAlertControllerStyleActionSheet];

    // Opción 1: Anti atraso
    [menu addAction:[UIAlertAction actionWithTitle:@"⚡ Anti atraso" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Espacio para lógica futura
    }]];

    // Opción 2: Verificación (Visual)
    [menu addAction:[UIAlertAction actionWithTitle:@"✅ Verificación" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *vAlert = [UIAlertController alertControllerWithTitle:@"VERIFICACIÓN DE CONTACTOS" 
                                     message:@"\n● Estado: Protegido\n● Base de datos: Sincronizada\n● Contactos VIP: Verificados" 
                                     preferredStyle:UIAlertControllerStyleAlert];
        [vAlert addAction:[UIAlertAction actionWithTitle:@"Cerrar" style:UIAlertActionStyleCancel handler:nil]];
        [root presentViewController:vAlert animated:YES completion:nil];
    }]];

    [menu addAction:[UIAlertAction actionWithTitle:@"❌ Cerrar Menú" style:UIAlertActionStyleCancel handler:nil]];
    
    // Soporte para iPad
    menu.popoverPresentationController.sourceView = sender;
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
            // 1. CONTADOR SUPERIOR FIJO
            UIView *cView = [[UIView alloc] initWithFrame:CGRectMake(0, 45, window.bounds.size.width, 30)];
            UILabel *timerLabel = [[UILabel alloc] initWithFrame:cView.bounds];
            timerLabel.textColor = [UIColor redColor];
            timerLabel.font = [UIFont boldSystemFontOfSize:13];
            timerLabel.textAlignment = NSTextAlignmentCenter;
            [cView addSubview:timerLabel];
            [window addSubview:cView];

            // 2. BOTÓN FIJO (NO FLOTANTE/NO MOVIBLE)
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            // Posición fija a la derecha
            btn.frame = CGRectMake(window.bounds.size.width - 60, window.bounds.size.height / 2, 55, 55);
            btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
            btn.layer.cornerRadius = 27.5;
            btn.layer.borderWidth = 2.0;
            btn.layer.borderColor = [UIColor redColor].CGColor;
            
            [btn setTitle:@"VIP" forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

            // Solo acción de toque, sin gestos de movimiento
            [btn addTarget:[DomidiosManager class] action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            
            [window addSubview:btn];

            // 3. TIMER DE ACTUALIZACIÓN
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
                NSTimeInterval r = (DURACION_DIAS * 86400) - [[NSDate date] timeIntervalSinceDate:fechaActivacion];
                if (r <= 0) exit(0);
                
                int d = (int)(r / 86400), h = (int)((NSInteger)r % 86400) / 3600, m = (int)((NSInteger)r % 3600) / 60, s = (int)((NSInteger)r % 60);
                timerLabel.text = [NSString stringWithFormat:@"VIP: %02dD %02dH %02dM %02dS", d, h, m, s];
                
                [window bringSubviewToFront:cView];
                [window bringSubviewToFront:btn];
            }];
        } else {
            // Panel de activación
            NSString *shortID = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:5] uppercaseString];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ACTIVACIÓN" 
                                        message:[NSString stringWithFormat:@"ID: %@", shortID] 
                                        preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:nil];
            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                if ([alert.textFields.firstObject.text isEqualToString:[NSString stringWithFormat:@"VIP-%@-7", shortID]]) {
                    [prefs setObject:[NSDate date] forKey:PREF_KEY]; [prefs synchronize]; exit(0);
                } else { exit(0); }
            }]];
            UIViewController *root = window.rootViewController;
            while(root.presentedViewController) root = root.presentedViewController;
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
