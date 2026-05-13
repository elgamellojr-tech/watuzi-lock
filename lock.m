#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

// --- MANAGER TOTALMENTE DINÁMICO ---
@interface FondoDomiManager : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) id player;
@property (nonatomic, strong) id looper;
@property (nonatomic, strong) id playerLayer;
+ (instancetype)shared;
@end

@implementation FondoDomiManager

+ (instancetype)shared {
    static FondoDomiManager *s = nil;
    static dispatch_once_t o;
    dispatch_once(&o, ^{ s = [[self alloc] init]; });
    return s;
}

- (void)abrirExplorador {
    dlopen("/System/Library/Frameworks/AVFoundation.framework/AVFoundation", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/AVKit.framework/AVKit", RTLD_LAZY);
    dlopen("/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers", RTLD_LAZY);

    Class pickerCls = NSClassFromString(@"UIDocumentPickerViewController");
    if (!pickerCls) return;

    id picker = nil;
    if (@available(iOS 14.0, *)) {
        Class utCls = NSClassFromString(@"UTType");
        if (utCls) {
            id movieType = [utCls valueForKey:@"movie"];
            picker = [[pickerCls alloc] initForOpeningContentTypes:@[movieType]];
        }
    } 
    
    if (!picker) {
        picker = [[pickerCls alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];
    }

    [picker setValue:self forKey:@"delegate"];
    
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root && root.presentedViewController) root = root.presentedViewController;
    if (root) [root presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    UIWindow *win = [UIApplication sharedApplication].keyWindow;
    if (self.playerLayer) [(CALayer *)self.playerLayer removeFromSuperlayer];

    Class playerItemCls = NSClassFromString(@"AVPlayerItem");
    Class queuePlayerCls = NSClassFromString(@"AVQueuePlayer");
    Class playerLayerCls = NSClassFromString(@"AVPlayerLayer");
    Class looperCls = NSClassFromString(@"AVPlayerLooper");

    id item = ((id (*)(id, SEL, id))objc_msgSend)(playerItemCls, sel_registerName("playerItemWithURL:"), url);
    self.player = ((id (*)(id, SEL, id))objc_msgSend)(queuePlayerCls, sel_registerName("queuePlayerWithItems:"), @[item]);
    self.playerLayer = ((id (*)(id, SEL, id))objc_msgSend)(playerLayerCls, sel_registerName("playerLayerWithPlayer:"), self.player);

    [(CALayer *)self.playerLayer setFrame:win.bounds];
    [self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
    [(CALayer *)self.playerLayer setZPosition:-1];

    if (looperCls) {
        self.looper = [[looperCls alloc] performSelector:sel_registerName("initWithPlayer:templateItem:") withObject:self.player withObject:item];
    }
    
    [win.layer insertSublayer:self.playerLayer atIndex:0];
    ((void (*)(id, SEL))objc_msgSend)(self.player, sel_registerName("play"));
}

- (void)crearBoton:(UIWindow *)win {
    if ([win viewWithTag:8899]) return;

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 8899;
    btn.frame = CGRectMake(30, 200, 55, 55);
    btn.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.7];
    btn.layer.cornerRadius = 27.5;
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor whiteColor].CGColor;
    [btn setTitle:@"📁" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(abrirExplorador) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
    [btn addGestureRecognizer:pan];
    [win addSubview:btn];
}

- (void)moveBtn:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:p.view.superview];
    p.view.center = CGPointMake(p.view.center.x + t.x, p.view.center.y + t.y);
    // SOLUCIÓN AL ERROR: Usamos CGPointMake en lugar de CGPointZero
    [p setTranslation:CGPointMake(0, 0) inView:p.view.superview];
}
@end

// --- INICIALIZADOR ---
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *shortID = [[deviceID substringToIndex:5] uppercaseString];
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (id scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene respondsToSelector:sel_registerName("activationState")] && 
                    (NSInteger)[scene performSelector:sel_registerName("activationState")] == 0) {
                    window = [[scene performSelector:sel_registerName("windows")] firstObject];
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        UIViewController *root = window.rootViewController;
        while (root && root.presentedViewController) root = root.presentedViewController;
        if (!root) return;

        if ([prefs objectForKey:@"fecha_registro_domidios"]) {
            [[FondoDomiManager shared] crearBoton:window];
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
