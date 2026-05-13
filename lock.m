#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>

@interface DomiMenu : UIView
@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) UISwitch *crashSwitch;
@property (nonatomic, strong) UISwitch *timeSwitch;
+ (instancetype)shared;
- (void)show;
@end

@implementation DomiMenu

+ (instancetype)shared {
    static DomiMenu *menu = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ menu = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds]; });
    return menu;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
        _container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 320)];
        _container.center = self.center;
        _container.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        _container.layer.cornerRadius = 20;
        _container.layer.borderWidth = 2;
        _container.layer.borderColor = [UIColor cyanColor].CGColor;
        [self addSubview:_container];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 280, 40)];
        title.text = @"🛡️ DOMIDIOS MODS";
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:18];
        [_container addSubview:title];

        // --- SWITCHES ---
        self.crashSwitch = [self addOption:@"Anti-Crash System" y:70 selector:@selector(toggleCrash:)];
        self.timeSwitch = [self addOption:@"Anti-Time Bypass" y:130 selector:@selector(toggleTime:)];
        
        // Botón FLEX
        UIButton *flexBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, 200, 200, 40)];
        flexBtn.backgroundColor = [UIColor systemBlueColor];
        flexBtn.layer.cornerRadius = 10;
        [flexBtn setTitle:@"Open FLEX 3" forState:UIControlStateNormal];
        [flexBtn addTarget:self action:@selector(openFlex) forControlEvents:UIControlEventTouchUpInside];
        [_container addSubview:flexBtn];

        // Botón Cerrar
        UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(100, 260, 80, 35)];
        [close setTitle:@"CERRAR" forState:UIControlStateNormal];
        [close setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
        [close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [_container addSubview:close];
    }
    return self;
}

- (UISwitch *)addOption:(NSString *)name y:(CGFloat)y selector:(SEL)sel {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 180, 30)];
    lbl.text = name;
    lbl.textColor = [UIColor lightGrayColor];
    [_container addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(210, y, 50, 30)];
    sw.onTintColor = [UIColor cyanColor];
    [sw addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:name];
    [_container addSubview:sw];
    return sw;
}

- (void)toggleCrash:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:@"Anti-Crash System"]; }
- (void)toggleTime:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:@"Anti-Time Bypass"]; }

- (void)openFlex {
    dlopen("/Library/MobileSubstrate/DynamicLibraries/FLEX.dylib", RTLD_LAZY);
    Class mgr = NSClassFromString(@"FLEXManager");
    if (mgr) [[mgr performSelector:@selector(sharedManager)] performSelector:@selector(showExplorer)];
    [self hide];
}

- (void)show { [[UIApplication sharedApplication].keyWindow addSubview:self]; self.hidden = NO; }
- (void)hide { self.hidden = YES; }
@end

// --- LÓGICA DE LICENCIA E INICIALIZACIÓN ---
__attribute__((constructor))
static void domidios_init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        // --- PARCHE: ANTI-ATRASO (Si el switch está ON) ---
        if ([prefs boolForKey:@"Anti-Time Bypass"]) {
            NSDate *last = [prefs objectForKey:@"last_date"];
            if (last && [[NSDate date] compare:last] == NSOrderedAscending) exit(0);
            [prefs setObject:[NSDate date] forKey:@"last_date"];
        }

        NSString *shortID = [[[[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:5] uppercaseString];
        NSDate *reg = [prefs objectForKey:@"fecha_registro_domidios"];

        if (reg) {
            NSTimeInterval rest = (30 * 86400) - [[NSDate date] timeIntervalSinceDate:reg];
            if (rest <= 0) { [prefs removeObjectForKey:@"fecha_registro_domidios"]; exit(0); }

            // CREAR BOTÓN FLOTANTE DEL MENÚ
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(20, 100, 55, 55);
            btn.backgroundColor = [UIColor blackColor];
            btn.layer.cornerRadius = 27.5;
            btn.layer.borderWidth = 2;
            btn.layer.borderColor = [UIColor cyanColor].CGColor;
            [btn setTitle:@"DOMI" forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:12 bold:YES];
            [btn addTarget:[DomiMenu shared] action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
            
            // Hacer movible
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:btn action:@selector(move:)];
            [btn addGestureRecognizer:pan];
            objc_setAssociatedObject(btn, @selector(move:), ^(UIPanGestureRecognizer *p){
                p.view.center = CGPointMake(p.view.center.x + [p translationInView:p.view.superview].x, p.view.center.y + [p translationInView:p.view.superview].y);
                [p setTranslation:CGPointZero inView:p.view.superview];
            }, OBJC_ASSOCIATION_COPY_NONATOMIC);
            
            [window addSubview:btn];
        } else {
            // Lógica de activación... (Pedir Key VIP+ID+7)
            UIViewController *root = window.rootViewController;
            while(root.presentedViewController) root = root.presentedViewController;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ACTIVACIÓN" message:shortID preferredStyle:1];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Key..."; }];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:0 handler:^(UIAlertAction *a) {
                if ([alert.textFields.firstObject.text containsString:shortID]) {
                    [prefs setObject:[NSDate date] forKey:@"fecha_registro_domidios"];
                    exit(0);
                }
            }]];
            [root presentViewController:alert animated:YES completion:nil];
        }
    });
}
