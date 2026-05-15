#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- VISTA DE LA BARRA PERSONALIZADA ---
@interface MyCustomBar : UIView
@property (nonatomic, assign) UITabBarController *tabBarController; // Referencia para controlar WhatsApp
@property (nonatomic, strong) UIView *selectionIndicator;
@end

@implementation MyCustomBar

- (instancetype)initWithFrame:(CGRect)frame controller:(UITabBarController *)controller {
    self = [super initWithFrame:frame];
    if (self) {
        _tabBarController = controller;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES; // Permite toques

        // Efecto Blur
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        blur.userInteractionEnabled = NO;
        [self addSubview:blur];

        // Indicador Gris (Fondo de selección)
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        // Botón Chats
        UIButton *chatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        chatBtn.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [chatBtn setTitle:@"Chats" forState:UIControlStateNormal];
        chatBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [chatBtn addTarget:self action:@selector(didTapChats) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:chatBtn];

        // Botón Perfil
        UIButton *profileBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        profileBtn.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [profileBtn setTitle:@"Perfil" forState:UIControlStateNormal];
        profileBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        
        // --- MENÚ CON OPCIONES ---
        if (@available(iOS 14.0, *)) {
            UIAction *verEstado = [UIAction actionWithTitle:@"Ver Estados" image:[UIImage systemImageNamed:@"circle.dashed"] identifier:nil handler:^(__kindof UIAction *action) {
                [self goToTab:0]; // Tab 0 suele ser Estados/Novedades
            }];
            UIAction *verPerfil = [UIAction actionWithTitle:@"Mi Perfil" image:[UIImage systemImageNamed:@"person.circle"] identifier:nil handler:^(__kindof UIAction *action) {
                [self goToTab:4]; // Tab 4 suele ser Configuración/Tú
            }];
            
            profileBtn.menu = [UIMenu menuWithTitle:@"" children:@[verEstado, verPerfil]];
            profileBtn.showsMenuAsPrimaryAction = YES; // Abre el menú al tocar
        }

        [self addSubview:profileBtn];
    }
    return self;
}

- (void)didTapChats {
    [self goToTab:3]; // Tab 3 suele ser Chats
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
}

- (void)goToTab:(NSInteger)index {
    if (self.tabBarController) {
        [self.tabBarController setSelectedIndex:index];
    }
}

@end

// --- LÓGICA DE CONTROL ---
static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);

void hooked_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);

    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    NSString *className = NSStringFromClass([self class]);

    if ([className isEqualToString:@"WATabBarController"]) {
        UITabBarController *tabC = (UITabBarController *)self;
        tabC.tabBar.hidden = YES; // Esconde la barra vieja

        MyCustomBar *myBar = (MyCustomBar *)[keyWindow viewWithTag:888];
        if (!myBar) {
            CGFloat w = 280;
            CGFloat h = 65;
            myBar = [[MyCustomBar alloc] initWithFrame:CGRectMake((keyWindow.frame.size.width-w)/2, keyWindow.frame.size.height-100, w, h) controller:tabC];
            myBar.tag = 888;
            [keyWindow addSubview:myBar];
        }
        myBar.hidden = NO;
        [keyWindow bringSubviewToFront:myBar]; // Lo pone siempre por encima
    } 
    else if ([className containsString:@"ChatView"] || [className containsString:@"MessageList"]) {
        UIView *myBar = [keyWindow viewWithTag:888];
        if (myBar) myBar.hidden = YES;
    }
}

__attribute__((constructor))
static void initialize() {
    Class targetClass = objc_getClass("WATabBarController");
    if (targetClass) {
        Method m = class_getInstanceMethod(targetClass, @selector(viewDidAppear:));
        orig_viewDidAppear = (void *)method_getImplementation(m);
        method_setImplementation(m, (IMP)hooked_viewDidAppear);
    }
}
