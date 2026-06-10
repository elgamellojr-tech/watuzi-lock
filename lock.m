#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- DECLARACIONES INTERNAS DE WHATSAPP ---
@interface WAUserJID : NSObject
@property (nonatomic, copy, readonly) NSString *user;
@end

@interface WAPresenceInfo : NSObject
@property (nonatomic, readonly) WAUserJID *userJID;
@property (nonatomic, readonly) unsigned long long presence; 
@end


// Diccionario global en memoria para guardar estados (1 = Online, 2 = Offline)
static NSMutableDictionary *onlineUsersStatus = nil;


// ==========================================================
// 1. RECEPTOR DE ESTADOS (CAPTURA SEÑAL DEL SERVIDOR)
// ==========================================================
@interface NSObject (WhatsAppPresenceHook)
- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo;
@end

@implementation NSObject (WhatsAppPresenceHook)

- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo {
    [self custom_updatePresenceInfo:presenceInfo]; // Llama al original

    if (presenceInfo != nil && presenceInfo.userJID != nil) {
        NSString *phoneNumber = presenceInfo.userJID.user;
        unsigned long long status = presenceInfo.presence;

        if (!onlineUsersStatus) {
            onlineUsersStatus = [[NSMutableDictionary alloc] init];
        }

        if (status == 1) {
            [onlineUsersStatus setObject:@(1) forKey:phoneNumber];
        } else {
            [onlineUsersStatus setObject:@(2) forKey:phoneNumber];
        }

        // Forzar a la pantalla de chats a redibujarse para actualizar el color del punto
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIApplication sharedApplication] keyWindow] setNeedsLayout];
            [[[UIApplication sharedApplication] keyWindow] layoutIfNeeded];
        });
    }
}
@end


// ==========================================================
// 2. RENDERIZADO VISUAL (DIBUJA EL COLO EN LA FOTO DE PERFIL)
// ==========================================================
@interface UITableViewCell (WhatsAppCellHook)
- (void)custom_layoutSubviews;
@end

@implementation UITableViewCell (WhatsAppCellHook)

- (void)custom_layoutSubviews {
    [self custom_layoutSubviews]; // Llama al diseño original de la celda

    NSString *className = NSStringFromClass([self class]);
    
    // Filtramos para actuar SOLO en celdas de chat o contactos de WhatsApp
    if ([className containsString:@"ChatSessionCell"] || 
        [className containsString:@"ContactTableViewCell"] || 
        [className containsString:@"WAContactCell"]) {
        
        NSString *phoneNumber = nil;
        
        // Extraemos el número de teléfono asignado a la celda de forma dinámica
        @try {
            id session = nil;
            if ([self respondsToSelector:sel_registerName("chatSession")]) {
                session = [self valueForKey:@"chatSession"];
            } else if ([self respondsToSelector:sel_registerName("contact")]) {
                session = [self valueForKey:@"contact"];
            }
            
            id jid = [session valueForKey:@"jid"];
            phoneNumber = [jid valueForKey:@"user"];
        } @catch (NSException *exception) {
            phoneNumber = nil;
        }

        // Buscamos la foto de perfil (Avatar View)
        UIView *avatar = nil;
        if ([self respondsToSelector:sel_registerName("avatarView")]) {
            avatar = [self performSelector:sel_registerName("avatarView")];
        } else {
            // Si el método no responde, buscamos la vista interna por su tipo de clase
            for (UIView *subview in self.contentView.subviews) {
                NSString *subviewClass = NSStringFromClass([subview class]);
                if ([subviewClass containsString:@"Avatar"] || [subviewClass containsString:@"WAProfile"]) {
                    avatar = subview;
                    break;
                }
            }
        }

        // Si encontramos la foto y el número de teléfono, colocamos el punto indicador
        if (avatar && phoneNumber) {
            NSInteger indicatorTag = 99123;
            UIView *existingIndicator = [avatar viewWithTag:indicatorTag];

            // Revisamos el diccionario
            NSNumber *statusNumber = [onlineUsersStatus objectForKey:phoneNumber];
            NSInteger currentStatus = (statusNumber != nil) ? [statusNumber integerValue] : 2; // Por defecto: Desconectado (2)

            // Si ya existe el punto, lo removemos para actualizar su color correctamente
            if (existingIndicator) {
                [existingIndicator removeFromSuperview];
            }

            // Crear el círculo indicador
            CGFloat size = 13.0; // Un poco más grande para que se note bien
            UIView *statusDot = [[UIView alloc] initWithFrame:CGRectMake(avatar.bounds.size.width - size - 1, 
                                                                         avatar.bounds.size.height - size - 1, 
                                                                         size, 
                                                                         size)];
            statusDot.layer.cornerRadius = size / 2.0;
            statusDot.layer.borderWidth = 1.8;
            statusDot.layer.borderColor = [UIColor whiteColor].CGColor; // Borde blanco nítido
            statusDot.tag = indicatorTag;
            statusDot.clipsToBounds = YES;

            if (currentStatus == 1) {
                // VERDE: Conectado
                statusDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.84 blue:0.29 alpha:1.0];
            } else {
                // GRIS OSCURO: Desconectado o sin registro previo aún
                statusDot.backgroundColor = [UIColor colorWithRed:0.55 green:0.55 blue:0.55 alpha:1.0];
            }

            [avatar addSubview:statusDot];
            [avatar bringSubviewToFront:statusDot];
        }
    }
}
@end


// ==========================================================
// 3. INYECTOR NATIVO AL ABRIR LA IPA
// ==========================================================
__attribute__((constructor)) static void initialize_lock_tweak() {
    onlineUsersStatus = [[NSMutableDictionary alloc] init];

    // Interceptamos WAPresenceManager para capturar los datos de red
    Class presenceClass = objc_getClass("WAPresenceManager");
    if (presenceClass) {
        Method origMethod = class_getInstanceMethod(presenceClass, sel_registerName("updatePresenceInfo:"));
        Method newMethod = class_getInstanceMethod([NSObject class], @selector(custom_updatePresenceInfo:));
        if (origMethod && newMethod) {
            method_exchangeImplementations(origMethod, newMethod);
        }
    }

    // Buscamos e interceptamos el diseño de las celdas de la lista
    Class cellClass = objc_getClass("WAChatSessionCell");
    if (!cellClass) cellClass = objc_getClass("WAContactTableViewCell");
    if (!cellClass) cellClass = objc_getClass("UITableViewCell"); // Respaldo global

    if (cellClass) {
        Method origCellMethod = class_getInstanceMethod(cellClass, @selector(layoutSubviews));
        Method newCellMethod = class_getInstanceMethod([UITableViewCell class], @selector(custom_layoutSubviews));
        if (origCellMethod && newCellMethod) {
            method_exchangeImplementations(origCellMethod, newCellMethod);
            NSLog(@"[DOMIDIOS] Sistema visual forzado e inyectado con éxito.");
        }
    }
}
