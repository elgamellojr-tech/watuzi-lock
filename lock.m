#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>

// --- CARGA DINÁMICA ---
__attribute__((constructor))
static void load_sys_libs() {
    dlopen("/System/Library/Frameworks/AVFoundation.framework/AVFoundation", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/AVKit.framework/AVKit", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers", RTLD_LAZY);
}

@interface FondoDomiManager : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) id player;
@property (nonatomic, strong) id looper;
@property (nonatomic, strong) id playerLayer;
+ (instancetype)shared;
- (void)showPicker;
@end

@implementation FondoDomiManager

+ (instancetype)shared {
    static FondoDomiManager *s = nil;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)showPicker {
    Class pickerCls = NSClassFromString(@"UIDocumentPickerViewController");
    if (!pickerCls) return;

    id picker;
    // Soporte para iOS 14+ y versiones anteriores sin errores de tipos
    if (@available(iOS 14.0, *)) {
        Class utCls = NSClassFromString(@"UTType");
        id movieType = [utCls valueForKey:@"movie"];
        picker = [[pickerCls alloc] initForOpeningContentTypes:@[movieType]];
    } else {
        picker = [[pickerCls alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];
    }

    [picker setDelegate:self];
    
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;
    [root presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    if (self.playerLayer) [(CALayer *)self.playerLayer removeFromSuperlayer];

    // Creación de objetos AVFoundation mediante strings
    id item = [NSClassFromString(@"AVPlayerItem") performSelector:@selector(playerItemWithURL:) withObject:url];
    self.player = [NSClassFromString(@"AVQueuePlayer") performSelector:@selector(queuePlayerWithItems:) withObject:@[item]];
    self.playerLayer = [NSClassFromString(@"AVPlayerLayer") performSelector:@selector(playerLayerWithPlayer:) withObject:self.player];

    [(CALayer *)self.playerLayer setFrame:win.bounds];
    [self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
    [(CALayer *)self.playerLayer setZPosition:-1];

    self.looper = [[NSClassFromString(@"AVPlayerLooper") alloc] performSelector:@selector(initWithPlayer:templateItem:) withObject:self.player withObject:item];
    
    [win.layer insertSublayer:self.playerLayer atIndex:0];
    [self.player performSelector:@selector(play)];
}

- (void)crearBoton:(UIWindow *)win {
    if ([win viewWithTag:8899]) return;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 8899;
    btn.frame = CGRectMake(30, 200, 55, 55);
    btn.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
    btn.layer.cornerRadius = 27.5;
    btn.layer.shadowOpacity = 0.5;
    [btn setTitle:@"📁" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(showPicker) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
    [btn addGestureRecognizer:pan];
    [win addSubview:btn];
}

- (void)moveBtn:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:p.view.superview];
    p.view.center = CGPointMake(p.view.center.x + t.x, p.view.center.y + t.y);
    [p setTranslation:CGPointZero inView:p.view.superview];
}
@end

// --- LÓGICA DE LICENCIA ---
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fecha = [prefs objectForKey:@"fecha_registro_domidios"];
        NSString *shortID = [[[[[UIDevice currentDevice] identifierForVendor] UUIDString] substringToIndex:5] uppercaseString];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window && @available(iOS 13.0, *)) {
            for (id scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene activationState] == 0) {
                    window = [[scene windows] firstObject];
                    break;
                }
            }
        }
        
        UIViewController *root = window.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        if (!root) return;

        if (fecha) {
            if ([[NSDate date] timeIntervalSinceDate:fecha] >= (30 * 86400)) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                exit(0);
            } else {
                [[FondoDomiManager shared] crearBoton:window];
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ VIP" message:[NSString stringWithFormat:@"ID: %@", shortID] preferredStyle:1];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key..."; tf.secureTextEntry = YES; }];
            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:0 handler:^(UIAlertAction *a) {
                NSString *k = alert.textFields.firstObject.text;
                if ([k hasPrefix:@"VIP"] && [k hasSuffix:@"7"] && [k containsString:shortID]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    [[FondoDomiManager shared] crearBoton:window];
                } else { exit(0); }
            }]];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
