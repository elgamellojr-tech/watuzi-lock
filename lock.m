#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

// --- INTERFAZ DE LA BARRA ---
@interface MyCustomBar : UIView
@property (nonatomic, assign) UITabBarController *tabBarController;
@property (nonatomic, strong) UIView *selectionIndicator;
@end

@implementation MyCustomBar

- (instancetype)initWithFrame:(CGRect)frame controller:(UITabBarController *)controller {
    self = [super initWithFrame:frame];
    if (self) {
        _tabBarController = controller;
        
        // Estilo Cápsula
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES;

        // Efecto Blur
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        blur.userInteractionEnabled = NO;
        [self addSubview:blur];

        // Indicador Gris (Selección)
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2)-10, frame.size.height-10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        // Botón CHATS
        UIButton *btnChat = [UIButton buttonWithType:UIButtonTypeCustom];
        btnChat.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [btnChat setTitle:@"Chats" forState:UIControlStateNormal];
        [btnChat addTarget:self action:@selector(actionChats) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnChat];

        // Botón PERFIL (Con Menú)
        UIButton *btnPerfil = [UIButton buttonWithType:UIButtonTypeCustom];
        btnPerfil.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [btnPerfil setTitle:@"Perfil" forState:UIControlStateNormal];
        
        if (@available(iOS 14.0, *)) {
            UIAction *verEstado = [UIAction actionWithTitle:@"Ver Estados" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                if (self.tabBarController) [self.tabBarController setSelectedIndex:0];
            }];
            UIAction *verAjustes = [UIAction actionWithTitle:@"Ajustes" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                if (self.tabBarController) [self.tabBarController setSelectedIndex:4];
            }];
            btnPerfil.menu = [UIMenu menuWithTitle:@"" children:@[verEstado, verAjustes]];
            btnPerfil.showsMenuAsPrimaryAction = YES; // Abre menú al tocar
        }
        [self addSubview:btnPerfil];
    }
    return self;
}

- (void)actionChats {
    if (self.tabBarController) [self.tabBarController setSelectedIndex:3];
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
}

// Asegura que los botones reciban el toque siempre
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

@end

// --- HOOKS ---
static void (*orig_layout)(UIViewController *, SEL);

void hooked_layout(UIViewController *self, SEL _cmd) {
    orig_layout(self, _cmd);

    if (![NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) return;

    UITabBarController *tabC = (UITabBarController *)self;
    tabC.tabBar.hidden = YES; // Oculta original

    UIWindow *win = self.view.window;
    if (!win) return;

    MyCustomBar *bar = (MyCustomBar *)[win viewWithTag:888];
    if (!bar) {
        bar = [[MyCustomBar alloc] initWithFrame:CGRectMake((win.frame.size.width-280)/2, win.frame.size.height-100, 280, 65) controller:tabC];
        bar.tag = 888;
        [win addSubview:bar];
    }

    // Lógica para que NO estorbe en los chats
    BOOL isMain = (tabC.presentedViewController == nil && tabC.navigationController.viewControllers.count <= 1);
    bar.hidden = !isMain;
    if (isMain) [win bringSubviewToFront:bar];
}

__attribute__((constructor))
static void init() {
    Class c = objc_getClass("WATabBarController");
    if (c) {
        Method m = class_getInstanceMethod(c, @selector(viewDidLayoutSubviews));
        orig_layout = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_layout);
    }
}
