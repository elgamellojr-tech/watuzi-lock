#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- DECLARACIÓN DE CLASES INTERNAS DE WHATSAPP ---
@interface WAUserJID : NSObject
@property (nonatomic, copy, readonly) NSString *user;
@end

@interface WAPresenceInfo : NSObject
@property (nonatomic, readonly) WAUserJID *userJID;
@property (nonatomic, readonly) unsigned long long presence; // 1 = Online, 2 = Offline
@end


// --- CATEGORÍA PARA EL SWIZZLING ---
@interface NSObject (WhatsAppHook)
- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo;
@end

@implementation NSObject (WhatsAppHook)

- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo {
    // Ejecuta el método original de WhatsApp
    [self custom_updatePresenceInfo:presenceInfo];

    if (presenceInfo != nil && presenceInfo.userJID != nil) {
        NSString *phoneNumber = presenceInfo.userJID.user;
        unsigned long long status = presenceInfo.presence;

        // Variables para personalizar el mensaje de la alerta
        __block NSString *alertTitle = @"";
        __block NSString *alertMessage = @"";
        __block BOOL shouldShowAlert = NO;

        if (status == 1) {
            // CASO: CONECTADO
            alertTitle = @"🚨 ¡CONTACTO EN LÍNEA! 🚨";
            alertMessage = [NSString stringWithFormat:@"El número +%@ se acaba de conectar.", phoneNumber];
            shouldShowAlert = YES;
            NSLog(@"[DOMIDIOS] Usuario ONLINE: +%@", phoneNumber);
        } else if (status == 2) {
            // CASO: DESCONECTADO
            alertTitle = @"💤 CONTACTO DESCONECTADO 💤";
            alertMessage = [NSString stringWithFormat:@"El número +%@ se ha desconectado.", phoneNumber];
            shouldShowAlert = YES;
            NSLog(@"[DOMIDIOS] Usuario OFFLINE: +%@", phoneNumber);
        }

        // Si el estado es válido (1 o 2), lanzamos la alerta en pantalla
        if (shouldShowAlert) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                               message:alertMessage
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:okAction];
                
                // Buscar la pantalla frontal activa para encimar la alerta sin crasear la app
                UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                if (rootVC) {
                    while (rootVC.presentedViewController) {
                        rootVC = rootVC.presentedViewController;
                    }
                    [rootVC presentViewController:alert animated:YES completion:nil];
                }
            });
        }
    }
}

@end


// --- CONSTRUCTOR NATIVO (Se ejecuta al abrir la IPA) ---
__attribute__((constructor)) static void initialize_hooks() {
    Class targetClass = objc_getClass("WAPresenceManager");
    
    if (targetClass) {
        SEL originalSelector = sel_registerName("updatePresenceInfo:");
        SEL swizzledSelector = @selector(custom_updatePresenceInfo:);
        
        Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod([NSObject class], swizzledSelector);
        
        if (originalMethod && swizzledMethod) {
            BOOL didAddMethod = class_addMethod(targetClass,
                                                originalSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                class_replaceMethod(targetClass,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            NSLog(@"[DOMIDIOS] Swizzling completo para Conectado/Desconectado.");
        }
    }
}
