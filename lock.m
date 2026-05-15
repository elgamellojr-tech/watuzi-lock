#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
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

// --- HOOK SEGURO ---
static void (*orig_viewDidLayout)(UIViewController *, SEL);

void hooked_viewDidLayout(UIViewController *self, SEL _cmd) {
    orig_viewDidLayout(self, _cmd);

    // Solo ejecutar si la clase es WATabBarController
    if (![NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) return;

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    UITabBarController *tabC = (UITabBarController *)self;
    
    // Ocultar la original
    tabC.tabBar.hidden = YES;
    tabC.tabBar.alpha = 0;

    UIView *myBar = [keyWindow viewWithTag:888];
    if (!myBar) {
        CGFloat width = 280;
        CGFloat height = 65;
        myBar = [[MyCustomBar alloc] initWithFrame:CGRectMake(
            (keyWindow.frame.size.width - width) / 2,
            keyWindow.frame.size.height - 100,
            width,
            height
        )];
        myBar.tag = 888;
        [keyWindow addSubview:myBar];
    }

    // Lógica para ocultar la barra si NO estamos en la pantalla principal
    // Si hay un controlador presentado (como un chat abierto), ocultamos la barra
    if (self.presentedViewController || self.navigationController.viewControllers.count > 1) {
        myBar.hidden = YES;
    } else {
        myBar.hidden = NO;
        [keyWindow bringSubviewToFront:myBar];
    }
}

__attribute__((constructor))
static void init() {
    Class targetClass = objc_getClass("WATabBarController");
    if (targetClass) {
        Method m = class_getInstanceMethod(targetClass, @selector(viewDidLayoutSubviews));
        orig_viewDidLayout = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_viewDidLayout);
    }
}
