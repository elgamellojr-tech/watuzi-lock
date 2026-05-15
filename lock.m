#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

// --- VISTA PERSONALIZADA ---
@interface MyCustomBar : UIView
@property (nonatomic, strong) UITabBarController *parentController;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *profileButton;
@end

@implementation MyCustomBar

- (instancetype)initWithFrame:(CGRect)frame parent:(UITabBarController *)parent {
    self = [super initWithFrame:frame];
    if (self) {
        _parentController = parent;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES;

        // Efecto Blur
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        [self addSubview:blur];

        // Indicador de selección
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        // BOTÓN CHATS
        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"Chats" forState:UIControlStateNormal];
        [_chatButton addTarget:self action:@selector(goToChats) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_chatButton];

        // BOTÓN PERFIL
        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"Perfil" forState:UIControlStateNormal];
        
        // MENÚ DEL PERFIL (Ver Estado y Ajustes)
        if (@available(iOS 14.0, *)) {
            UIAction *verEstado = [UIAction actionWithTitle:@"Ver Estados" image:[UIImage systemImageNamed:@"circle.dashed"] identifier:nil handler:^(__kindof UIAction *action) {
                [self goToUpdates];
            }];
            UIAction *ajustes = [UIAction actionWithTitle:@"Ajustes" image:[UIImage systemImageNamed:@"gear"] identifier:nil handler:^(__kindof UIAction *action) {
                [self goToSettings];
            }];
            
            _profileButton.menu = [UIMenu menuWithTitle:@"" children:@[verEstado, ajustes]];
            _profileButton.showsMenuAsPrimaryAction = YES;
        }
        [self addSubview:_profileButton];
    }
    return self;
}

// --- ACCIONES ---

- (void)goToChats {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    // En WhatsApp, la pestaña 3 suele ser Chats (o la 0 según versión)
    if (_parentController) _parentController.selectedIndex = 3; 
}

- (void)goToUpdates {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake((self.frame.size.width/2)+5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    // La pestaña de "Novedades" (Estados)
    if (_parentController) _parentController.selectedIndex = 0;
}

- (void)goToSettings {
    // La pestaña de Ajustes (Tú/Perfil)
    if (_parentController) _parentController.selectedIndex = 4;
}

@end

// --- HOOK ---
static void (*orig_viewDidLayout)(UIViewController *, SEL);

void hooked_viewDidLayout(UIViewController *self, SEL _cmd) {
    orig_viewDidLayout(self, _cmd);

    if (![NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) return;

    UITabBarController *tabC = (UITabBarController *)self;
    tabC.tabBar.hidden = YES; // Oculta la original

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    MyCustomBar *myBar = (MyCustomBar *)[keyWindow viewWithTag:888];
    if (!myBar) {
        myBar = [[MyCustomBar alloc] initWithFrame:CGRectMake((keyWindow.frame.size.width - 280)/2, keyWindow.frame.size.height - 100, 280, 65) parent:tabC];
        myBar.tag = 888;
        [keyWindow addSubview:myBar];
    }

    // Ocultar si entramos a un chat o cámara
    BOOL isInMain = (tabC.presentedViewController == nil && tabC.navigationController.viewControllers.count <= 1);
    myBar.hidden = !isInMain;
    if (isInMain) [keyWindow bringSubviewToFront:myBar];
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
