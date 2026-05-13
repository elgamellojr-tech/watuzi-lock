#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// --- MANAGER PARA EL FONDO ---
@interface FondoManager : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) AVPlayerLooper *looper;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
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
    UIDocumentPickerViewController *picker;
    if (@available(iOS 14.0, *)) {
        picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeMovie, UTTypeVideo, UTTypeMPEG4]];
    } else {
        picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.movie"] inMode:UIDocumentPickerModeImport];
    }
    picker.delegate = self;
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    if (self.playerLayer) [self.playerLayer removeFromSuperlayer];

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVQueuePlayer queuePlayerWithItems:@[item]];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = win.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.zPosition = -1; // Fondo detrás de todo

    self.looper = [AVPlayerLooper playerLooperWithPlayer:self.player templateItem:item];
    [win.layer insertSublayer:self.playerLayer atIndex:0];
    [self.player play];
}

- (void)crearBotonFlotante:(UIWindow *)window {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(20, 200, 55, 55);
    btn.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
    btn.layer.cornerRadius = 27.5;
    btn.layer.borderWidth = 2;
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    [btn setTitle:@"📁" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(abrirExplorador) forControlEvents:UIControlEventTouchUpInside];
    
    // Hacerlo arrastrable
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

// --- INICIO DEL TWEAK (TU CÓDIGO ORIGINAL MODIFICADO) ---
__attribute__((visibility("default")))
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
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

        if (fechaActivacion) {
            NSTimeInterval segundosTranscurridos = [[NSDate date] timeIntervalSinceDate:fechaActivacion];
            NSTimeInterval tiempoRestante = (30 * 86400) - segundosTranscurridos;

            if (tiempoRestante <= 0) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                exit(0);
            } else {
                // SI ESTÁ ACTIVADO: Creamos el botón de fondo
                [[FondoManager shared] crearBotonFlotante:window];
                
                int dias = (int)(tiempoRestante / 86400);
                NSString *statusMsg = [NSString stringWithFormat:@"ID: %@\n⏳ Vence en: %d días", deviceShortID, dias];
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" message:statusMsg preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
            }
        }

        if (![prefs objectForKey:@"fecha_registro_domidios"]) {
            // (Código de activación omitido por brevedad, es el mismo que ya tienes)
            // Solo asegúrate de llamar a [[FondoManager shared] crearBotonFlotante:window]; 
            // dentro del bloque de éxito del inputKey.
            
            // ... [Aquí va tu UIAlertController de activación] ...
        }
    });
}
