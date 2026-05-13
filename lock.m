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
                    if (movieType) picker = [[pickerCls alloc] initForOpeningContentTypes:@[movieType]];
                }
            } 
            
            if (!picker) picker = [[pickerCls alloc] initWithDocumentTypes:@[@"public.movie"] inMode:0];
            [picker setValue:self forKey:@"delegate"];
            
            UIWindow *keyWin = [UIApplication sharedApplication].keyWindow;
            UIViewController *root = keyWin.rootViewController;
            while (root.presentedViewController) root = root.presentedViewController;
            
            if (root) [root presentViewController:picker animated:YES completion:nil];
        } @catch (NSException *e) { NSLog(@"[DomiDios] Crash explorador: %@", e); }
    });
}

- (void)documentPicker:(id)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    [url startAccessingSecurityScopedResource];

    // Realizamos la copia en segundo plano para evitar lag
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *destPath = [docs stringByAppendingPathComponent:@"fondo_domi.mp4"];
            NSURL *destURL = [NSURL fileURLWithPath:destPath];

            if ([fm fileExistsAtPath:destPath]) [fm removeItemAtPath:destPath error:nil];
            
            NSError *err;
            [fm copyItemAtURL:url toURL:destURL error:&err];

            dispatch_async(dispatch_get_main_queue(), ^{
                [url stopAccessingSecurityScopedResource];
                if (!err) [self reproducirVideoURL:destURL];
            });
        } @catch (NSException *e) { 
            dispatch_async(dispatch_get_main_queue(), ^{ [url stopAccessingSecurityScopedResource]; });
        }
    });
}

- (void)reproducirVideoURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) return; // PROTECCIÓN: Si no hay ventana, no hacemos nada para evitar crash

        @try {
            if (self.playerLayer) {
                [(CALayer *)self.playerLayer removeFromSuperlayer];
                if (self.player) [self.player performSelector:sel_registerName("pause")];
                self.player = nil; self.playerLayer = nil; self.looper = nil;
            }

            Class playerItemCls = NSClassFromString(@"AVPlayerItem");
            Class queuePlayerCls = NSClassFromString(@"AVQueuePlayer");
            Class playerLayerCls = NSClassFromString(@"AVPlayerLayer");
            Class looperCls = NSClassFromString(@"AVPlayerLooper");

            if (!playerItemCls || !queuePlayerCls || !playerLayerCls) return;

            id item = ((id (*)(id, SEL, id))objc_msgSend)(playerItemCls, sel_registerName("playerItemWithURL:"), url);
            self.player = ((id (*)(id, SEL, id))objc_msgSend)(queuePlayerCls, sel_registerName("queuePlayerWithItems:"), @[item]);
            self.playerLayer = ((id (*)(id, SEL, id))objc_msgSend)(playerLayerCls, sel_registerName("playerLayerWithPlayer:"), self.player);

            [(CALayer *)self.playerLayer setFrame:win.bounds];
            [self.playerLayer setValue:@"AVLayerVideoGravityResizeAspectFill" forKey:@"videoGravity"];
            
            // IMPORTANTE: En IPAs modificadas, -1 a veces no es suficiente. Usamos un valor muy bajo.
            [(CALayer *)self.playerLayer setZPosition:-999]; 

            if (looperCls) {
                self.looper = [[looperCls alloc] performSelector:sel_registerName("initWithPlayer:templateItem:") withObject:self.player withObject:item];
            }
            
            [win.layer insertSublayer:self.playerLayer atIndex:0];
            ((void (*)(id, SEL))objc_msgSend)(self.player, sel_registerName("play"));
        } @catch (NSException *e) { NSLog(@"[DomiDios] Crash reproductor: %@", e); }
    });
}

// ... (El resto del código de mover botón e inicializador se mantiene igual)

- (void)crearBoton:(UIWindow *)win {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!win || [win viewWithTag:8899]) return;
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

// Inicializador (Constructor)
__attribute__((constructor))
static void domidios_premium_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDate *fechaRegistro = [prefs objectForKey:@"fecha_registro_domidios"];
        
        // Si ya está registrado, cargar video guardado inmediatamente
        if (fechaRegistro) {
            NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *videoPath = [docs stringByAppendingPathComponent:@"fondo_domi.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
                [[FondoDomiManager shared] reproducirVideoURL:[NSURL fileURLWithPath:videoPath]];
            }
            [[FondoDomiManager shared] crearBoton:window];
        } else {
            // Lógica de alerta de activación (omito texto largo por brevedad, usa la que ya tienes)
            [[FondoDomiManager shared] crearBoton:window];
        }
    });
}
