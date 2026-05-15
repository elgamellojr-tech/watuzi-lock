#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- VISTA PERSONALIZADA ---
@interface MyCustomBar : UIView
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *profileButton;
@end

@implementation MyCustomBar
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES;

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.frame = self.bounds;
        [self addSubview:_blurView];

        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"Chats" forState:UIControlStateNormal];
        [_chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _chatButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [self addSubview:_chatButton];

        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"Perfil" forState:UIControlStateNormal];
        [_profileButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _profileButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];

        if (@available(iOS 14.0, *)) {
            UIAction *ajustes = [UIAction actionWithTitle:@"Ajustes" image:nil identifier:nil handler:^(__kindof UIAction *action) {}];
            _profileButton.menu = [UIMenu menuWithTitle:@"" children:@[ajustes]];
            _profileButton.showsMenuAsPrimaryAction = YES;
        }
        [self addSubview:_profileButton];
    }
    return self;
}
@end

// --- HOOKING ---
static void (*orig_viewDidLayoutSubviews)(UIViewController *, SEL);

void hooked_viewDidLayoutSubviews(UIViewController *self, SEL _cmd) {
    orig_viewDidLayoutSubviews(self, _cmd);

    NSString *className = NSStringFromClass([self class]);
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

    if ([className isEqualToString:@"WATabBarController"]) {
        UITabBarController *tabController = (UITabBarController *)self;
        
        // 1. Ocultar la barra original agresivamente
        tabController.tabBar.hidden = YES;
        tabController.tabBar.alpha = 0;
        tabController.tabBar.frame = CGRectZero; 

        // 2. Manejar nuestra barra personalizada
        UIView *myBar = [keyWindow viewWithTag:888];
        if (!myBar) {
            CGFloat width = 280;
            CGFloat height = 65;
            myBar = [[MyCustomBar alloc] initWithFrame:CGRectMake(
                (keyWindow.frame.size.width - width) / 2,
                keyWindow.frame.size.height - 95,
                width,
                height
            )];
            myBar.tag = 888;
            [keyWindow addSubview:myBar];
        }
        
        // Siempre traer al frente para que no la tape nada
        [keyWindow bringSubviewToFront:myBar];
        myBar.hidden = NO;
    } 
    // Ocultar si entramos a un chat (identificando la clase del controlador de mensajes)
    else if ([className containsString:@"WAChat"] || [className containsString:@"Message"]) {
        UIView *myBar = [keyWindow viewWithTag:888];
        if (myBar) myBar.hidden = YES;
    }
}

__attribute__((constructor))
static void init() {
    // Usamos viewDidLayoutSubviews para que se ejecute cada vez que la UI se refresque
    Class targetClass = objc_getClass("WATabBarController");
    if (targetClass) {
        Method m = class_getInstanceMethod(targetClass, @selector(viewDidLayoutSubviews));
        orig_viewDidLayoutSubviews = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_viewDidLayoutSubviews);
    }
    
    // Hook adicional para asegurar que se oculte al entrar a cualquier otra pantalla
    Class baseClass = [UIViewController class];
    Method m2 = class_getInstanceMethod(baseClass, @selector(viewDidLayoutSubviews));
    orig_viewDidLayoutSubviews = (void *)method_getImplementation(m2);
    method_setImplementation(m2, (IMP)hooked_viewDidLayoutSubviews);
}
