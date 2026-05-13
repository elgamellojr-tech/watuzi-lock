#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
    dlopen("/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers", RTLD_LAZY);

    dispatch_async(dispatch_get_main_queue(), ^{
        Class pickerCls = NSClassFromString(@"UIDocumentPickerViewController");
        if (!pickerCls) return;

        id picker = nil;
        if (@available(iOS 14.0, *)) {
            Class utCls = NSClassFromString(@"UTType");
            id movieType = [utCls valueForKey:@"movie"];
            picker = [[pickerCls alloc] initForOpeningContentTypes:@[movieType]];
        } 
        if (!picker) picker = [[pickerCls alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];

        [picker setValue:self forKey:@"delegate"];
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (root && root.presentedViewController) root = root.presentedViewController;
        if (root) [root presentViewController:picker animated:YES completion:nil];
    });
}

- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    if ([url respondsToSelector:@selector(startAccessingSecurityScopedResource)]) [url performSelector:@selector(startAccessingSecurityScopedResource)];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (self.playerLayer) [(CALayer *)self.playerLayer removeFromSuperlayer];

        id item = ((id (*)(id, SEL, id))objc_msgSend)(NSClassFromString(@"AVPlayerItem"), sel_registerName("playerItemWithURL:"), url);
        self.player = ((id (*)(id, SEL, id))objc_msgSend)(NSClassFromString(@"AVQueuePlayer"), sel_registerName("queuePlayerWithItems:"), @[item]);
        self.playerLayer = ((id (*)(id, SEL, id))objc_msgSend)(NSClassFromString(@"AVPlayerLayer"), sel_registerName("playerLayerWithPlayer:"), self.player);

        [(CALayer *)self.playerLayer setFrame:win.bounds];
        [self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
        [(CALayer *)self.playerLayer setZPosition:-1];

        Class looperCls = NSClassFromString(@"AVPlayerLooper");
        if (looperCls) self.looper = [[looperCls alloc] performSelector:sel_registerName("initWithPlayer:templateItem:") withObject:self.player withObject:item];
        
        [win.layer insertSublayer:self.playerLayer atIndex:0];
        ((void (*)(id, SEL))objc_msgSend)(self.player, sel_registerName("play"));
    });
}

- (void)crearBoton:(UIWindow *)win {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([win viewWithTag:8899]) return;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 8899;
        btn.frame = CGRectMake(30, 200, 55, 55);
        btn.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.8];
        btn.layer.cornerRadius = 27.5;
        btn.layer.borderWidth = 1.5;
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        [btn setTitle:@"📁" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(abrirExplorador) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
        [btn addGestureRecognizer:pan];
        [win addSubview:btn];
    });
}

- (void)moveBtn:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:p.view.superview];
    p.view.center = CGPointMake(p.view.center.x + t.x, p.view.center.y + t.y);
    [p setTranslation:CGPointMake(0, 0) inView:p.view.superview];
}
@end

// --- INICIALIZADOR CON CONTADOR DE TIEMPO ---
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaRegistro = [prefs objectForKey:@"fecha_registro_domidios"];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        if (!window) return;
        UIViewController *root = window.rootViewController;
        while (root && root.presentedViewController) root = root.presentedViewController;
        if (!root) return;

        NSString *shortID = [[[[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:5] uppercaseString];

        if (fechaRegistro) {
            NSTimeInterval transcurrido = [[NSDate date] timeIntervalSinceDate:fechaRegistro];
            NSTimeInterval duracionTotal = 30 * 86400; // 30 días
            NSTimeInterval restante = duracionTotal - transcurrido;

            if (restante <= 0) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                UIAlertController *exp = [UIAlertController alertControllerWithTitle:@"⚠️ EXPIRADO" message:@"Tu licencia ha vencido." preferredStyle:1];
                [root presentViewController:exp animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ exit(0); });
            } else {
                // Cálculo de Días y Horas restantes
                int dias = (int)(restante / 86400);
                int horas = (int)(((long)restante % 86400) / 3600);
                
                [[FondoDomiManager shared] crearBoton:window];
                
                NSString *msg = [NSString stringWithFormat:@"ID: %@\n⏳ Tiempo: %d días y %d horas", shortID, dias, horas];
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" message:msg preferredStyle:1];
                [root presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ ACTIVACIÓN" message:[NSString stringWithFormat:@"ID: %@", shortID] preferredStyle:1];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key..."; tf.secureTextEntry = YES; }];
            [alert addAction:[UIAlertAction actionWithTitle:@"ACTIVAR" style:0 handler:^(UIAlertAction *a) {
                NSString *k = alert.textFields.firstObject.text;
                if ([k hasPrefix:@"VIP"] && [k hasSuffix:@"7"] && [k containsString:shortID]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    [prefs synchronize];
                    [[FondoDomiManager shared] crearBoton:window];
                    // Recargar para mostrar días/horas
                    exit(0); 
                } else { exit(0); }
            }]];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
