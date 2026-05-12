#import <UIKit/UIKit.h>

__attribute__((visibility("default")))
__attribute__((constructor))
static void init_domidios_lock() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *regDate = [prefs objectForKey:@"domidios_reg_date"];
        
        // Comprobar expiración (30 días)
        if (regDate) {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:regDate];
            if (elapsed > 2592000) { // 2,592,000 segundos = 30 días
                UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"iOS DOMIDIOS" 
                                            message:@"Tu licencia ha expirado.\nContacta al administrador." 
                                            preferredStyle:UIAlertControllerStyleAlert];
                [root presentViewController:alert animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
                return;
            }
        }

        // Interfaz de Bloqueo
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        UIViewController *vc = win.rootViewController;
        while (vc.presentedViewController) vc = vc.presentedViewController;

        UIAlertController *lock = [UIAlertController alertControllerWithTitle:@"SISTEMA DE ACCESO"
                                    message:@"Introduce tu Key de 30 días"
                                    preferredStyle:UIAlertControllerStyleAlert];

        [lock addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = @"WTDFGTHGUER";
            tf.secureTextEntry = YES;
        }];

        [lock addAction:[UIAlertAction actionWithTitle:@"Activar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = lock.textFields.firstObject.text;
            
            if ([key isEqualToString:@"WTDFGTHGUER"]) { // CAMBIA ESTO
                if (![prefs objectForKey:@"domidios_reg_date"]) {
                    [prefs setObject:[NSDate date] forKey:@"domidios_reg_date"];
                    [prefs synchronize];
                }
            } else {
                exit(0);
            }
        }]];

        [vc presentViewController:lock animated:YES completion:nil];
    });
}
