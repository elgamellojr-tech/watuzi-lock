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


// --- DECLARACIÓN DE LA FUNCIÓN DE SUBSTRATE ---
// Esto evita que el compilador dé error si no encuentra la librería de Substrate de golpe
#ifdef __cplusplus
extern "C" {
#endif
    void MSHookMessageEx(Class _class, SEL selector, IMP replacement, IMP *result);
#ifdef __cplusplus
}
#endif


// --- PUNTERO PARA GUARDAR EL MÉTODO ORIGINAL ---
static void (*orig_updatePresenceInfo)(id self, SEL _cmd, WAPresenceInfo *presenceInfo);


// --- NUESTRA FUNCIÓN REEMPLAZO (EL HOOK) ---
static void replaced_updatePresenceInfo(id self, SEL _cmd, WAPresenceInfo *presenceInfo) {
    // 1. Ejecutamos el método original obligatoriamente
    orig_updatePresenceInfo(self, _cmd, presenceInfo);

    // 2. Lógica para detectar el estado "En Línea"
    if (presenceInfo != nil && presenceInfo.userJID != nil) {
        NSString *phoneNumber = presenceInfo.userJID.user;
        unsigned long long status = presenceInfo.presence;

        // status == 1 significa "En Línea"
        if (status == 1) {
            
            // Forzar ejecución en el hilo principal para la interfaz gráfica
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚨 ¡CONTACTO EN LÍNEA! 🚨"
                                                                               message:[NSString stringWithFormat:@"El número +%@ se acaba de conectar.", phoneNumber]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:okAction];
                
                // Buscar la pantalla de enfrente para mostrar la alerta sin crasear
                UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                if (rootVC) {
                    while (rootVC.presentedViewController) {
                        rootVC = rootVC.presentedViewController;
                    }
                    [rootVC presentViewController:alert animated:YES completion:nil];
                }
            });

            // Log en la consola del dispositivo
            NSLog(@"[DOMIDIOS] Usuario online detectado: +%@", phoneNumber);
        }
    }
}


// --- CONSTRUCTOR: SE EJECUTA AL CARGAR EL DYLIB EN LA IPA ---
__attribute__((constructor)) static void initialize_hooks() {
    // Buscamos la clase dentro de WhatsApp
    Class targetClass = objc_getClass("WAPresenceManager");
    
    if (targetClass) {
        SEL targetSelector = sel_registerName("updatePresenceInfo:");
        
        // Aplicamos el Hook usando la API nativa de Substrate
        MSHookMessageEx(targetClass, 
                        targetSelector, 
                        (IMP)replaced_updatePresenceInfo, 
                        (IMP *)&orig_updatePresenceInfo);
        
        NSLog(@"[DOMIDIOS] Hook aplicado con éxito en WAPresenceManager.");
    } else {
        NSLog(@"[DOMIDIOS] Error: No se encontró la clase WAPresenceManager.");
    }
}
