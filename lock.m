#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <ifaddrs.h>
#include <net/if.h>

// --- Instancia Global Única ---
static UILabel *networkSpeedLabel = nil;

// Variables para el cálculo de bytes
static uint32_t lastInputBytes = 0;
static uint32_t lastOutputBytes = 0;

// ============================================================================
// LÓGICA NATIVA DE VELOCIDAD (KB/s)
// ============================================================================
static void updateNetworkSpeed() {
    struct ifaddrs *ifa_list = 0;
    struct ifaddrs *ifa = 0;
    
    uint32_t iBytes = 0;
    uint32_t oBytes = 0;
    
    if (getifaddrs(&ifa_list) == 0) {
        for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr->sa_family == AF_LINK) {
                struct if_data *if_data = (struct if_data *)ifa->ifa_data;
                if (if_data) {
                    iBytes += if_data->ifi_ibytes;
                    oBytes += if_data->ifi_obytes;
                }
            }
        }
        freeifaddrs(ifa_list);
    }
    
    float speedUpload = 0.0;
    float speedDownload = 0.0;
    
    if (lastInputBytes > 0 && lastOutputBytes > 0) {
        speedDownload = (iBytes - lastInputBytes) / 1024.0;
        speedUpload = (oBytes - lastOutputBytes) / 1024.0;
        
        if (speedDownload < 0) speedDownload = 0;
        if (speedUpload < 0) speedUpload = 0;
    }
    
    lastInputBytes = iBytes;
    lastOutputBytes = oBytes;
    
    if (networkSpeedLabel) {
        networkSpeedLabel.text = [NSString stringWithFormat:@" ↑ %.1f KB/s  ↓ %.1f KB/s ", speedUpload, speedDownload];
    }
}

// ============================================================================
// CREADOR SEGURO DEL MONITOR (EVITA DUPLICADOS)
// ============================================================================
static void verificarYCrearMonitor() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWin = [UIApplication sharedApplication].keyWindow;
        if (!keyWin) return;
        
        // Si ya existe en la ventana, solo lo traemos al frente por si se ocultó
        if (networkSpeedLabel && [networkSpeedLabel isDescendantOfView:keyWin]) {
            [keyWin bringSubviewToFront:networkSpeedLabel];
            return;
        }
        
        // Dimensiones del monitor
        CGFloat labelWidth = 190;
        CGFloat labelHeight = 25; // Altura optimizada para el espacio libre
        CGFloat screenWidth = keyWin.frame.size.width;
        CGFloat posX = (screenWidth - labelWidth) / 2.0;
        
        // CORRECCIÓN PRECISA: Subido de 44 a 28 para esquivar perfectamente el texto de los chats
        CGFloat posY = 28; 
        
        networkSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake(posX, posY, labelWidth, labelHeight)];
        networkSpeedLabel.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.09 alpha:0.85];
        networkSpeedLabel.textColor = [UIColor whiteColor];
        networkSpeedLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightBold];
        networkSpeedLabel.textAlignment = NSTextAlignmentCenter;
        networkSpeedLabel.layer.cornerRadius = 12.5;
        networkSpeedLabel.clipsToBounds = YES;
        networkSpeedLabel.layer.borderWidth = 1.0;
        networkSpeedLabel.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1.0].CGColor;
        networkSpeedLabel.text = @" ↑ 0.0 KB/s  ↓ 0.0 KB/s ";
        
        [keyWin addSubview:networkSpeedLabel];
        [keyWin bringSubviewToFront:networkSpeedLabel];
    });
}

// ============================================================================
// RECEPTOR DE EVENTOS DEL SISTEMA (ENTRAR/SALIR DE LA APP)
// ============================================================================
@interface DOMIDIOSNetworkObserver : NSObject
@end

@implementation DOMIDIOSNetworkObserver
+ (void)load {
    static DOMIDIOSNetworkObserver *sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[DOMIDIOSNetworkObserver alloc] init];
        
        // Escucha cuando la app se abre o vuelve a estar activa
        [[NSNotificationCenter defaultCenter] addObserver:sharedObserver
                                                 selector:@selector(appFocalizada)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        // Inicializa el bucle del medidor de KB/s global de fondo
        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            updateNetworkSpeed();
        }];
    });
}

- (void)appFocalizada {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        verificarYCrearMonitor();
    });
}
@end

// ============================================================================
// CONSTRUCTOR INICIALIZADOR
// ============================================================================
__attribute__((constructor)) static void initInyectorPersistente() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        verificarYCrearMonitor();
    });
}
