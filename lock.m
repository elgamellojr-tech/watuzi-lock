__attribute__((constructor))
static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Intentamos obtener la ventana activa de varias formas
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        }
        
        if (!window) window = [UIApplication sharedApplication].keyWindow;

        UIViewController *rootVC = window.rootViewController;
        
        // Si hay un controlador presentado, lo usamos para mostrar nuestra alerta encima
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }

        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DOMIDIOS SECURITY"
                                        message:@"iosDOMIDIOS"
                                        preferredStyle:UIAlertControllerStyleAlert];
            // ... resto de tu código de botones ...
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
