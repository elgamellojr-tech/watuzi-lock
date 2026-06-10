#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- DECLARACIONES INTERNETAS DE WHATSAPP ---
@interface WAUserJID : NSObject
@property (nonatomic, copy, readonly) NSString *user;
@end

@interface WAPresenceInfo : NSObject
@property (nonatomic, readonly) WAUserJID *userJID;
@property (nonatomic, readonly) unsigned long long presence; // 1 = Online, 2 = Offline
@end

@interface WAChatSessionCell : UITableViewCell
@property (nonatomic, strong) id chatSession; 
- (id)avatarView; 
@end

// Diccionario global para guardar los estados en tiempo real
static NSMutableDictionary *onlineUsersStatus = nil;


// ==========================================================
// 1. HOOK DE PRESENCIA (CAPTURA CONECTADO / DESCONECTADO)
// ==========================================================
@interface NSObject (WhatsAppPresenceHook)
- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo;
@end

@implementation NSObject (WhatsAppPresenceHook)

- (void)custom_updatePresenceInfo:(WAPresenceInfo *)presenceInfo {
    [self custom_updatePresenceInfo:presenceInfo];

    if (presenceInfo != nil && presenceInfo.userJID != nil) {
        NSString *phoneNumber = presenceInfo.userJID.user;
        unsigned long long status = presenceInfo.presence;

        if (!onlineUsersStatus) {
            onlineUsersStatus = [[NSMutableDictionary alloc] init];
        }

        if (status == 1) {
            // Guardamos estado: CONECTADO (NSNumber con valor 1)
            [onlineUsersStatus setObject:@(1) forKey:phoneNumber];
            NSLog(@"[DOMIDIOS] +%@ está ONLINE", phoneNumber);
        } else if (status == 2) {
            // Guardamos estado: DESCONECTADO (NSNumber con valor 2)
            [onlineUsersStatus setObject:@(2) forKey:phoneNumber];
            NSLog(@"[DOMIDIOS] +%@ está OFFLINE", phoneNumber);
        }

        // Forzar recarga visual instantánea en la pantalla principal
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            if (keyWindow) {
                [[keyWindow valueForKeyPath:@"rootViewController.view"] setNeedsLayout];
            }
        });
    }
}
@end


// ==========================================================
// 2. HOOK DE INTERFAZ (PINTA VERDE O GRIS EN LA FOTO)
// ==========================================================
@interface UITableViewCell (WhatsAppCellHook)
- (void)custom_layoutSubviews;
@end

@implementation UITableViewCell (WhatsAppCellHook)

- (void)custom_layoutSubviews {
    [self custom_layoutSubviews];

    // Verificamos si es una celda de chat o de contacto de WhatsApp
    if ([NSStringFromClass([self class]) isEqualToString:@"WAChatSessionCell"] || 
        [NSStringFromClass([self class]) isEqualToString:@"WAContactTableViewCell"]) {
        
        NSString *phoneNumber = nil;
        
        @try {
            id session = [self valueForKey:@"chatSession"];
            id jid = [session valueForKey:@"jid"];
            phoneNumber = [jid valueForKey:@"user"];
        } @catch (NSException *exception) {
            phoneNumber = nil;
        }

        UIView *avatar = nil;
        if ([self respondsToSelector:@selector(avatarView)]) {
            avatar = [self performSelector:@selector(avatarView)];
        } else {
            for (UIView *subview in self.contentView.subviews) {
                if ([NSStringFromClass([subview class]) containsString:@"Avatar"] || 
                    [NSStringFromClass([subview class]) isEqualToString:@"WRAvatarImageView"]) {
                    avatar = subview;
                    break;
                }
            }
        }

        if (avatar && phoneNumber) {
            NSInteger indicatorTag = 99123;
            UIView *existingIndicator = [avatar viewWithTag:indicatorTag];

            // Obtenemos el estado almacenado (1 = Online, 2 = Offline, nil = Desconocido todavía)
            NSNumber *statusNumber = [onlineUsersStatus objectForKey:phoneNumber];

            if (statusNumber != nil) {
                NSInteger status = [statusNumber integerValue];
                
                // Si ya existe el punto, lo removemos para redibujarlo con el color correcto sin encimarlos
                if (existingIndicator) {
                    [existingIndicator removeFromSuperview];
                }

                CGFloat size = 12.0;
                UIView *statusDot = [[UIView alloc] initWithFrame:CGRectMake(avatar.bounds.size.width - size - 2, 
                                                                             avatar.bounds.size.height - size - 2, 
                                                                             size, 
                                                                             size)];
                statusDot.layer.cornerRadius = size / 2.0;
                statusDot.layer.borderWidth = 1.5;
                statusDot.layer.borderColor = [UIColor whiteColor].CGColor; // Borde blanco limpio
                statusDot.tag = indicatorTag;
                statusDot.clipsToBounds = YES;

                if (status == 1) {
                    // Círculo Verde si está En Línea
                    statusDot.backgroundColor = [UIColor colorWithRed:0.20 green:0.84 blue:0.29 alpha:1.0];
                } else if (status == 2) {
                    // Círculo Gris Oscuro si está Desconectado
                    statusDot.backgroundColor = [UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0];
                }

                [avatar addSubview:statusDot];
                [avatar bringSubviewToFront:statusDot];
            }
        }
    }
}
@end


// ==========================================================
// 3. CONSTRUCTOR (INICIALIZACIÓN NATIVA)
// ==========================================================
__attribute__((constructor)) static void initialize_lock_tweak() {
    onlineUsersStatus = [[NSMutableDictionary alloc] init];

    // Inicializar Swizzling de Datos
    Class presenceClass = objc_getClass("WAPresenceManager");
    if (presenceClass) {
        Method origMethod = class_getInstanceMethod(presenceClass, sel_registerName("updatePresenceInfo:"));
        Method newMethod = class_getInstanceMethod([NSObject class], @selector(custom_updatePresenceInfo:));
        if (origMethod && newMethod) {
            method_exchangeImplementations(origMethod, newMethod);
        }
    }

    // Inicializar Swizzling de Vista Visual
    Class cellClass = objc_getClass("WAChatSessionCell");
    if (!cellClass) {
        cellClass = objc_getClass("UITableViewCell");
    }
    
    if (cellClass) {
        Method origCellMethod = class_getInstanceMethod(cellClass, @selector(layoutSubviews));
        Method newCellMethod = class_getInstanceMethod([UITableViewCell class], @selector(custom_layoutSubviews));
        if (origCellMethod && newCellMethod) {
            method_exchangeImplementations(origCellMethod, newCellMethod);
            NSLog(@"[DOMIDIOS] Sistema visual dual (Online/Offline) inyectado.");
        }
    }
}
