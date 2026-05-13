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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            Class pickerCls = NSClassFromString(@"UIDocumentPickerViewController");
            if (!pickerCls) return;

            id picker = nil;
            if (@available(iOS 14.0, *)) {
                dlopen("/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers", RTLD_LAZY);
                Class utCls = NSClassFromString(@"UTType");
                if (utCls) {
                    id movieType = [utCls performSelector:sel_registerName("typeWithIdentifier:") withObject:@"public.movie"];
                    if (movieType) {
                        picker = [[pickerCls alloc] initForOpeningContentTypes:@[movieType]];
                    }
                }
            } 
            
            if (!picker) {
                picker = [[pickerCls alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];
            }

            [picker setValue:self forKey:@"delegate"];
            
            UIWindow *keyWin = nil;
            if (@available(iOS 13.0, *)) {
                for (id scene in [UIApplication sharedApplication].connectedScenes) {
                    if ([scene respondsToSelector:@selector(windows)]) {
                        for (UIWindow *w in [scene performSelector:@selector(windows)]) {
                            if (w.isKeyWindow) { keyWin = w; break; }
                        }
                    }
                }
            }
            if (!keyWin) keyWin = [UIApplication sharedApplication].keyWindow;
            
            UIViewController *root = keyWin.rootViewController;
            while (root.presentedViewController) root = root.presentedViewController;
            
            if (root) [root presentViewController:picker animated:YES completion:nil];
        } @catch (NSException *exception) {
            NSLog(@"[DomiDios] Error al abrir el explorador: %@", exception);
        }
    });
}

// NUEVA LÓGICA: Copia el video a la carpeta local para que Watusi lo reconozca siempre
- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    [url startAccessingSecurityScopedResource];

    @try {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *destPath = [docs stringByAppendingPathComponent:@"fondo_domi.mp4"];
        NSURL *destURL = [NSURL fileURLWithPath:destPath];

        if ([fm fileExistsAtPath:destPath]) {
            [fm removeItemAtPath:destPath error:nil];
        }

        NSError *err;
        [fm copyItemAtURL:url toURL:destURL error:&err];

        if (!err) {
            [self reproducirVideoURL:destURL];
        } else {
            NSLog(@"[DomiDios] Error al copiar: %@", err);
        }
    } @catch (NSException *e) {
        NSLog(@"[DomiDios] Fallo: %@", e);
    } @finally {
        [url stopAccessingSecurityScopedResource];
    }
}

- (void)reproducirVideoURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        
        if (self.playerLayer) {
            [(CALayer *)self.playerLayer removeFromSuperlayer];
            if (self.player) [self.player performSelector:sel_registerName("pause")];
            self.player = nil;
            self.playerLayer = nil;
            self.looper = nil;
        }

        Class playerItemCls = NSClassFromString(@"AVPlayerItem");
        Class queuePlayerCls = NSClassFromString(@"AVQueuePlayer");
        Class playerLayerCls = NSClassFromString(@"AVPlayerLayer");
        Class looperCls = NSClassFromString(@"AVPlayerLooper");

        if (!playerItemCls || !queuePlayerCls) return;

        id item = ((id (*)(id, SEL, id))objc_msgSend)(playerItemCls, sel_registerName("playerItemWithURL:"), url);
        self.player = ((id (*)(id, SEL, id))objc_msgSend)(queuePlayerCls, sel_registerName("queuePlayerWithItems:"), @[item]);
        self.playerLayer = ((id (*)(id, SEL, id))objc_msgSend)(playerLayerCls, sel_registerName("playerLayerWithPlayer:"), self.player);

        [(CALayer *)self.playerLayer setFrame:win.bounds];
        [self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
        [(CALayer *)self.playerLayer setZPosition:-10]; // Ajustado para quedar detrás de los chats

        if (looperCls) {
            self.looper = [[looperCls alloc] performSelector:sel_registerName("initWithPlayer:templateItem:") withObject:self.player withObject:item];
        }
        
        [win.layer insertSublayer:self.playerLayer atIndex:0];
        ((void (*)(id, SEL))objc_msgSend)(self.player, sel_registerName("play"));
    });
}

- (void)crearBoton:(UIWindow *)win {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([win viewWithTag:8899]) return;

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 8899;
        btn.frame = CGRectMake(30, 200, 60, 60);
        btn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        btn.layer.cornerRadius = 30;
        btn.layer.borderWidth = 2;
        btn.layer.borderColor = [UIColor cyanColor].CGColor;
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

// --- INICIALIZADOR CON LICENCIA ---
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
            NSTimeInterval restante = (30 * 86400) - [[NSDate date] timeIntervalSinceDate:fechaRegistro];

            if (restante <= 0) {
                [prefs removeObjectForKey:@"fecha_registro_domidios"];
                [prefs synchronize];
                exit(0);
            } else {
                int d = (int)(restante / 86400);
                int h = (int)(((long)restante % 86400) / 3600);
                
                // Cargar el video guardado al iniciar si existe
                NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                NSString *videoPath = [docs stringByAppendingPathComponent:@"fondo_domi.mp4"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
                    [[FondoDomiManager shared] reproducirVideoURL:[NSURL fileURLWithPath:videoPath]];
                }
                
                [[FondoDomiManager shared] crearBoton:window];
                
                UIAlertController *status = [UIAlertController alertControllerWithTitle:@"🛡️ STATUS VIP" 
                                            message:[NSString stringWithFormat:@"ID: %@\n⏳ Restante: %d d y %d h", shortID, d, h] 
                                            preferredStyle:1];
                [root presentViewController:status animated:YES completion:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [status dismissViewControllerAnimated:YES completion:nil]; });
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
                } else { exit(0); }
            }]];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
