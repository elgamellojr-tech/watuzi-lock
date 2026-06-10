#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- DECLARACIÓN DE CLASES INTERNAS DE WHATSAPP ---
@interface WAUserJID : NSObject
@property (nonatomic, copy, readonly) NSString *user;
@end

@interface WAPresenceInfo : NSObject
@property (nonatomic, readonly) WAUserJID *userJID;
@property (nonatomic, readonly) unsigned long long presence;
@end


// --- CATEGORÍA PARA EL SWIZZLING ---
@interface NSObject (WhatsAppHook)
- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo;
@end

@implementation NSObject (WhatsAppHook)

- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo {
    // Debido al Swizzling, llamar a 'custom_updatePresenceInfo' aquí adentro
    // en realidad ejecuta el método original de WhatsApp. No es un bucle infinito.
    [self custom_updatePresenceInfo:presenceInfo];

    // Lógica para detectar si el contacto está "En Línea"
    if (presenceInfo != nil && presenceInfo.userJID != nil) {
        NSString *phoneNumber = presenceInfo.userJID.user;
        unsigned long long status = presenceInfo.presence;

        // status == 1 significa "En Línea"
        if (status == 1) {
            
            // Ejecución segura en la interfaz gráfica (UI)
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚨 ¡CONTACTO EN LÍNEA! 🚨"
                                                                               message:[NSString stringWithFormat:@"El número +%@ se acaba de conectar.", phoneNumber]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:okAction];
                
                // Buscar la pantalla frontal activa para mostrar la alerta
                UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                if (rootVC) {
                    while (rootVC.presentedViewController) {
                        rootVC = rootVC.presentedViewController;
                    }
                    [rootVC presentViewController:alert animated:YES completion:nil];
                }
            });

            // Registro en la consola
            NSLog(@"[DOMIDIOS] Usuario online detectado: +%@", phoneNumber);
        }
    }
}

@end


// --- CONSTRUCTOR: INTERCAMBIA LOS MÉTODOS NATIVAMENTE ---
__attribute__((constructor)) static void initialize_hooks() {
    // Buscamos la clase original de WhatsApp
    Class targetClass = objc_getClass("WAPresenceManager");
    
    if (targetClass) {
        SEL originalSelector = sel_registerName("updatePresenceInfo:");
        SEL swizzledSelector = @selector(custom_updatePresenceInfo:);
        
        Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod([NSObject class], swizzledSelector);
        
        if (originalMethod && swizzledMethod) {
            // Añadimos el método nuevo a la clase de WhatsApp si no existe
            BOOL didAddMethod = class_addMethod(targetClass,
                                                originalSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
                // Si se añadió, reemplazamos el método espejo
                class_replaceMethod(targetClass,
                                    swizzledSelector,
                                    method_getImplementation(originalMethod),
                                    method_getTypeEncoding(originalMethod));
            } else {
                // Si el método ya existía, simplemente intercambiamos sus implementaciones nativas
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
            
            NSLog(@"[DOMIDIOS] Swizzling aplicado con éxito de forma nativa.");
        } else {
            NSLog(@"[DOMIDIOS] Error: No se pudieron obtener los métodos.");
        }
    } else {
        NSLog(@"[DOMIDIOS] Error: No se encontró la clase WAPresenceManager en este binario.");
    }
}
