#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

// --- VISTA PERSONALIZADA ---
@interface MyCustomBar : UIView
// Usamos assign para evitar el error de sintaxis en compilación manual
@property (nonatomic, assign) UITabBarController *parentController;
@property (nonatomic, retain) UIView *selectionIndicator;
@property (nonatomic, retain) UIButton *chatButton;
@property (nonatomic, retain) UIButton *profileButton;
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

        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        blur.userInteractionEnabled = NO;
        [self addSubview:blur];

        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        _selectionIndicator.userInteractionEnabled = NO;
        [self addSubview:_selectionIndicator];

        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"Chats" forState:UIControlStateNormal];
        [_chatButton addTarget:self action:@selector(goToChats) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_chatButton];

        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"Perfil" forState:UIControlStateNormal];
        
        if (@available(iOS 14.0, *)) {
            UIAction *verEstado = [UIAction actionWithTitle:@"Ver Estados" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self goToUpdates];
            }];
            UIAction *ajustes = [UIAction actionWithTitle:@"Ajustes" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self goToSettings];
            }];
            _profileButton.menu = [UIMenu menuWithTitle:@"" children:@[verEstado, ajustes]];
            _profileButton.showsMenuAsPrimaryAction = YES;
        } else {
            [_profileButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_profileButton];
    }
    return self;
}

- (void)goToChats {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) {
        [self.parentController setSelectedIndex:3];
    }
}

- (void)goToUpdates {
    if (self.parentController) {
        [self.parentController setSelectedIndex:0];
    }
}

- (void)goToSettings {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake((self.frame.size.width/2)+5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) {
        [self.parentController setSelectedIndex:4];
    }
}
@end

// --- HOOK ---
static void (*orig_viewDidLayout)(UIViewController *, SEL);

void hooked_viewDidLayout(UIViewController *self, SEL _cmd) {
    orig_viewDidLayout(self, _cmd);

    if (![NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) return;

    UITabBarController *tabC = (UITabBarController *)self;
    tabC.tabBar.hidden = YES;

    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow* window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }

    if (!keyWindow) return;

    MyCustomBar *myBar = (MyCustomBar *)[keyWindow viewWithTag:888];
    if (!myBar) {
        myBar = [[MyCustomBar alloc] initWithFrame:CGRectMake((keyWindow.frame.size.width - 280)/2, keyWindow.frame.size.height - 100, 280, 65) parent:tabC];
        myBar.tag = 888;
        [keyWindow addSubview:myBar];
    }

    [keyWindow bringSubviewToFront:myBar];

    BOOL isInMain = (tabC.presentedViewController == nil && tabC.navigationController.viewControllers.count <= 1);
    myBar.hidden = !isInMain;
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
