#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <ifaddrs.h>
#include <net/if.h>

// --- Instancia Global del Monitor ---
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
// INYECCIÓN VISUAL BAJO LA ISLA DINÁMICA
// ============================================================================
static void (*original_viewDidAppear)(id, SEL, BOOL);

void custom_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    original_viewDidAppear(self, _cmd, animated);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewController *currentVC = (UIViewController *)self;
        UIWindow *keyWin = [UIApplication sharedApplication].keyWindow;
        
        // Dimensiones del monitor
        CGFloat labelWidth = 190;
        CGFloat labelHeight = 26;
        
        // Calculamos el centro horizontal exacto de la pantalla del iPhone
        CGFloat screenWidth = currentVC.view.frame.size.width;
        CGFloat posX = (screenWidth - labelWidth) / 2.0;
        
        // Posición Y calculada justo debajo de la Isla Dinámica (aprox 54 puntos arriba)
        CGFloat posY = 54;
        
        // Crear el diseño idéntico en negro traslúcido
        networkSpeedLabel = [[UILabel alloc] initWithFrame:CGRectMake(posX, posY, labelWidth, labelHeight)];
        networkSpeedLabel.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.09 alpha:0.85];
        networkSpeedLabel.textColor = [UIColor whiteColor];
        networkSpeedLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        networkSpeedLabel.textAlignment = NSTextAlignmentCenter;
        networkSpeedLabel.layer.cornerRadius = 13;
        networkSpeedLabel.clipsToBounds = YES;
        networkSpeedLabel.layer.borderWidth = 1.0;
        networkSpeedLabel.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1.0].CGColor;
        networkSpeedLabel.text = @" ↑ 0.0 KB/s  ↓ 0.0 KB/s ";
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (keyWin) {
                [keyWin addSubview:networkSpeedLabel];
                [keyWin bringSubviewToFront:networkSpeedLabel];
                
                // Temporizador para refrescar los datos cada segundo
                [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    updateNetworkSpeed();
                }];
            }
        });
    });
}

// ============================================================================
// CONSTRUCTOR CENTRAL
// ============================================================================
__attribute__((constructor)) static void initInyectorVelocidadTop() {
    Class targetClass = NSClassFromString(@"WASingleChatListViewController");
    if (!targetClass) targetClass = NSClassFromString(@"WAHomeViewController");
    if (!targetClass) targetClass = [UITabBarController class];
    
    SEL originalSelector = @selector(viewDidAppear:);
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    
    original_viewDidAppear = (void *)method_getImplementation(originalMethod);
    method_setImplementation(originalMethod, (IMP)custom_viewDidAppear);
}
