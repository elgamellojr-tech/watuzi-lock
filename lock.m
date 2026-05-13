#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- CARGA DINÁMICA DE FRAMEWORKS (Para no tocar el Makefile) ---
__attribute__((constructor))
static void load_frameworks() {
    dlopen("/System/Library/Frameworks/AVFoundation.framework/AVFoundation", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/AVKit.framework/AVKit", RTLD_LAZY);
    if (@available(iOS 14.0, *)) {
        dlopen("/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers", RTLD_LAZY);
    }
}

// --- MANAGER DEL FONDO ---
@interface FondoManager : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) id player;
@property (nonatomic, strong) id looper;
@property (nonatomic, strong) id playerLayer;
+ (instancetype)shared;
- (void)crearBotonFlotante:(UIWindow *)window;
@end

@implementation FondoManager
+ (instancetype)shared {
    static FondoManager *s = nil;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)abrirExplorador {
    Class pickerClass = NSClassFromString(@"UIDocumentPickerViewController");
    if (!pickerClass) return;

    id picker;
    if (@available(iOS 14.0, *)) {
        // Usamos strings para evitar dependencias de UniformTypeIdentifiers en el Makefile
        picker = [[pickerClass alloc] initForOpeningContentTypes:@[[NSClassFromString(@"UTType") valueForKey:@"movie"], [NSClassFromString(@"UTType") valueForKey:@"video"]]];
    } else {
        picker = [[pickerClass alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];
    }
    
    [picker setDelegate:self];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    
    if (self.playerLayer) [(CALayer *)self.playerLayer removeFromSuperlayer];

    Class itemClass = NSClassFromString(@"AVPlayerItem");
    Class queueClass = NSClassFromString(@"AVQueuePlayer");
    Class layerClass = NSClassFromString(@"AVPlayerLayer");
    Class looperClass = NSClassFromString(@"AVPlayerLooper");

    id item = [itemClass performSelector:@selector(playerItemWithURL:) withObject:url];
    self.player = [queueClass performSelector:@selector(queuePlayerWithItems:) withObject:@[item]];
    self.playerLayer = [layerClass performSelector:@selector(playerLayerWithPlayer:) withObject:self.player];
    
    [(CALayer *)self.playerLayer setFrame:win.bounds];
    [(id)self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
    [(CALayer *)self.playerLayer setZPosition:-1];

    self.looper = [looperClass performSelector:@selector(playerLooperWithPlayer:templateItem:) withObject:self.player withObject:item];
    [win.layer insertSublayer:self.playerLayer atIndex:0];
    [self.player performSelector:@selector(play)];
}

- (void)crearBotonFlotante:(UIWindow *)window {
    if ([window viewWithTag:9988]) return; // Evita duplicados
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 9988;
    btn.frame = CGRectMake(20, 200, 55, 55);
    btn.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
    btn.layer.cornerRadius = 27.5;
    btn.layer.borderWidth = 2;
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    [btn setTitle:@"📁" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(abrirExplorador) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [btn addGestureRecognizer:pan];
    [window addSubview:btn];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    pan.view.center = CGPointMake(pan.view.center.x + translation.x, pan.view.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
}
@end

// --- INICIO DE LA LÓGICA PRINCIPAL ---
__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaActivacion = [prefs objectForKey:@"fecha_registro_domidios"];
        
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *deviceShortID = [[deviceID substringToIndex:5] uppercaseString];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window && @available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = ((UIWindowScene*)scene).windows.firstObject;
                    break;
                }
            }
        }
        
        UIViewController *rootVC = window.rootViewController;
        while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
        if (!rootVC) return;

        // CASO 1: YA ESTÁ ACTIVADO
        if (fechaActivacion) {
            NSTimeInterval segundos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            if (segundos >= (30 * 86400)) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                exit(0);
            } else {
                [[FondoManager shared] crearBotonFlotante:window];
                int dias = (int)((30 * 86400 - segundos) / 86400);
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" message:[NSString stringWithFormat:@"ID: %@\n⏳ Vence en: %d días", deviceShortID, dias] preferredStyle:1];
                [rootVC presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
            }
        } 
        // CASO 2: NO ACTIVADO (PRIMERA VEZ)
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN" message:[NSString stringWithFormat:@"Tu ID: %@\nIntroduce tu llave VIP.", deviceShortID] preferredStyle:1];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key..."; tf.secureTextEntry = YES; }];

            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:0 handler:^(UIAlertAction *action) {
                NSString *key = alert.textFields.firstObject.text;
                if ([key hasPrefix:@"VIP"] && [key hasSuffix:@"7"] && [key containsString:deviceShortID]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    [[FondoManager shared] crearBotonFlotante:window];
                } else {
                    exit(0);
                }
            }]];
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
