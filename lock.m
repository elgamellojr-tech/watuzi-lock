#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

@interface MyCustomBar : UIView
@property (nonatomic, assign) UITabBarController *parentController;
@property (nonatomic, retain) UIView *selectionIndicator;
@end

@implementation MyCustomBar

- (instancetype)initWithFrame:(CGRect)frame parent:(UITabBarController *)parent {
    self = [super initWithFrame:frame];
    if (self) {
        _parentController = parent;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES; // IMPORTANTE

        // Blur de fondo
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        blur.userInteractionEnabled = NO;
        [self addSubview:blur];

        // Indicador Gris
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2)-10, frame.size.height-10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        _selectionIndicator.userInteractionEnabled = NO;
        [self addSubview:_selectionIndicator];

        // BOTÓN IZQUIERDO (CHATS)
        UIButton *btnChat = [UIButton buttonWithType:UIButtonTypeCustom];
        btnChat.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [btnChat setTitle:@"Chats" forState:UIControlStateNormal];
        [btnChat addTarget:self action:@selector(tapChat) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnChat];

        // BOTÓN DERECHO (PERFIL/ESTADOS)
        UIButton *btnPerfil = [UIButton buttonWithType:UIButtonTypeCustom];
        btnPerfil.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [btnPerfil setTitle:@"Perfil" forState:UIControlStateNormal];
        
        // Menú Nativo de iOS
        if (@available(iOS 14.0, *)) {
            UIAction *act1 = [UIAction actionWithTitle:@"Ver Estados" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self tapEstado];
            }];
            UIAction *act2 = [UIAction actionWithTitle:@"Ajustes" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self tapAjustes];
            }];
            btnPerfil.menu = [UIMenu menuWithTitle:@"" children:@[act1, act2]];
            btnPerfil.showsMenuAsPrimaryAction = YES;
        } else {
            [btnPerfil addTarget:self action:@selector(tapAjustes) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:btnPerfil];
    }
    return self;
}

// Lógica de cambio de pestañas
- (void)tapChat {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) [self.parentController setSelectedIndex:3]; // Chats suele ser 3
}

- (void)tapEstado {
    if (self.parentController) [self.parentController setSelectedIndex:0]; // Estados es 0
}

- (void)tapAjustes {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake((self.frame.size.width/2)+5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) [self.parentController setSelectedIndex:4]; // Configuración es 4
}

// Esto asegura que la barra detecte los toques aunque haya cosas "debajo"
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil; 
    return hitView;
}

@end

// --- HOOK ---
static void (*orig_layout)(UIViewController *, SEL);

void hooked_layout(UIViewController *self, SEL _cmd) {
    orig_layout(self, _cmd);

    if (![NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) return;

    UITabBarController *tab = (UITabBarController *)self;
    tab.tabBar.hidden = YES;
    tab.tabBar.userInteractionEnabled = NO;

    UIWindow *win = self.view.window;
    if (!win) return;

    MyCustomBar *bar = (MyCustomBar *)[win viewWithTag:888];
    if (!bar) {
        bar = [[MyCustomBar alloc] initWithFrame:CGRectMake((win.frame.size.width-280)/2, win.frame.size.height-100, 280, 65) parent:tab];
        bar.tag = 888;
        [win addSubview:bar];
    }
    
    [win bringSubviewToFront:bar]; // Forzar al frente
    
    // Ocultar si entramos a un chat
    BOOL isRoot = (tab.presentedViewController == nil && tab.navigationController.viewControllers.count <= 1);
    bar.hidden = !isRoot;
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
